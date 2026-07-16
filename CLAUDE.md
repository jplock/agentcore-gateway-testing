# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Path-scoped rules live in `.claude/rules/` (`terraform.md` for `*.tf` work, `inference-targets.md` for the CLI-managed gateway targets).

## Commands

All Terraform commands run from `environments/dev` — the only deployable root configuration. The module in `modules/agentcore-gateway` is never applied directly:

```bash
cd environments/dev
terraform init
terraform validate
terraform plan
terraform apply    # needs a recent AWS CLI v2 (inference targets are created via local-exec)
```

`validate` and `plan` are the default verification. Never run `terraform apply`, `terraform destroy`, or `scripts/inference-target.sh` unless explicitly asked — they create and delete real AWS resources, and dev state is local (no remote backend to recover from).

After an apply, watch gateway traffic echoed by the interceptor:

```bash
aws logs tail "$(terraform output -raw interceptor_log_group_name)" --follow
```

## Architecture

Two-layer Terraform layout:

- `modules/agentcore-gateway/` — opinionated module provisioning an Amazon Bedrock AgentCore Gateway (MCP protocol) that is privately reachable from a VPC, serves model inference at `/inference`, and echoes traffic through a Python interceptor Lambda. Everything useful is hardcoded on (semantic search, response streaming, DEBUG exception level, REQUEST+RESPONSE interception, both inference targets); only identity, auth, network placement, KMS, and tags are inputs.
- `environments/dev/` — dev root config: creates a minimal VPC (`terraform-aws-modules/vpc/aws`, private subnets only, no NAT/IGW) and instantiates the module. Uses local state by default; a remote backend stub is commented out in `versions.tf`.

Module files by concern:

- `main.tf` — the `aws_bedrockagentcore_gateway` resource; only the JWT authorizer block is conditional.
- `vpc.tf` — interface VPC endpoint (`com.amazonaws.<region>.bedrock-agentcore.gateway`) with private DNS plus its security group (HTTPS from the VPC CIDR).
- `inference.tf` + `scripts/inference-target.sh` — the `bedrock-mantle` connector target and `bedrock-runtime` provider target (OpenAI-compatible chat completions), managed via the AWS CLI (see `.claude/rules/inference-targets.md`).
- `lambda.tf` — the interceptor Lambda via `terraform-aws-modules/lambda/aws`, which packages `src/interceptor/handler.py` directly and also manages the execution role, CloudWatch log group, and the gateway→Lambda invoke permission (`allowed_triggers`).
- `iam.tf` / `data.tf` — the gateway's service role (trust policy carries confused-deputy conditions) with two inline policies: invoke-interceptor and bedrock-inference (Bedrock runtime `bedrock:InvokeModel*` + Mantle `bedrock-mantle:CreateInference`/`Get*`/`List*`).
- `locals.tf` — caller identity/region/partition exposed as `local.aws_account_id`, `local.aws_region`, `local.aws_partition`.

The interceptor (`modules/agentcore-gateway/src/interceptor/handler.py`) is a deliberate no-op: it logs the full event and returns it unchanged. The gateway treats the returned object as the in-flight payload, so any change to the return value mutates gateway traffic.

## Constraints

- AWS provider `>= 6.55.0`; Terraform `>= 1.5.0`; lambda module `>= 7.0.0`.
- Applies require a recent AWS CLI v2 with credentials for the target account — inference targets are created through `aws bedrock-agentcore-control`, outside Terraform's providers.
- PrivateLink adds private access but the gateway's public endpoint cannot be disabled; enforcing VPC-only access requires IAM conditions (e.g. `aws:SourceVpce`) on callers.
- Default inbound auth is `AWS_IAM`; `CUSTOM_JWT` requires `jwt_authorizer` (enforced by variable validation in `modules/agentcore-gateway/variables.tf`).
- MCP tool targets (`aws_bedrockagentcore_gateway_target`) are intentionally out of scope for the module — add them in the consuming configuration.
- Inference routing: clients pin a provider by prefixing the model with the target name (`bedrock-mantle/...` or `bedrock-runtime/...`); unqualified model IDs are matched across targets.
