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

A Makefile wraps these from the repo root: `make plan` / `make validate` / `make fmt` / `make shellcheck` (`ENV=dev` default).

`validate` and `plan` are the default verification. Never run `terraform apply`, `terraform destroy`, or `scripts/inference-target.sh` unless explicitly asked — they create and delete real AWS resources.

After an apply, watch gateway traffic echoed by the interceptor:

```bash
aws logs tail "$(terraform output -raw interceptor_log_group_name)" --follow
```

The gateway's own logs and its workload identity's logs land in separate groups (`gateway_log_group_name` / `identity_log_group_name` outputs); traces go to X-Ray via Transaction Search (`aws/spans` log group).

## Architecture

Two-layer Terraform layout:

- `modules/agentcore-gateway/` — opinionated module provisioning an Amazon Bedrock AgentCore Gateway (MCP protocol) that is privately reachable from a VPC, serves model inference at `/inference`, and echoes traffic through a Python interceptor Lambda. Everything useful is hardcoded on (semantic search, 1-hour MCP sessions, response streaming, DEBUG exception level, REQUEST+RESPONSE interception, both inference targets); only identity, auth, network placement, AWS profile, KMS, and tags are inputs.
- `environments/dev/` — dev root config: creates a minimal VPC (`terraform-aws-modules/vpc/aws`, private subnets only, no NAT/IGW) and instantiates the module. State lives in the S3 backend in `backend.tf`; the AWS provider profile comes from `var.aws_profile` (SSO profile by default, empty in CI for env-var credentials).

Module files by concern:

- `main.tf` — the `aws_bedrockagentcore_gateway` resource; only the JWT authorizer block is conditional.
- `vpc.tf` — interface VPC endpoint (`com.amazonaws.<region>.bedrock-agentcore.gateway`) with private DNS plus its security group (HTTPS from the VPC CIDR).
- `observability.tf` — vended log deliveries for `APPLICATION_LOGS` (CloudWatch log groups) and `TRACES` (X-Ray), covering both the gateway and its workload identity (the console's Gateway and Identity tabs). The account-level Transaction Search prerequisite lives in `environments/dev/observability.tf` (log resource policy + `aws_xray_trace_segment_destination` + 100% indexing rule); the module block in dev `depends_on` it so trace delivery doesn't race enablement.
- `inference.tf` + `scripts/inference-target.sh` — the `bedrock-mantle` connector target and `bedrock-runtime` provider target (OpenAI-compatible chat completions), managed via the AWS CLI (see `.claude/rules/inference-targets.md`).
- `lambda.tf` — the interceptor Lambda via `terraform-aws-modules/lambda/aws`, which packages `src/interceptor/handler.py` directly and also manages the execution role, CloudWatch log group, and the gateway→Lambda invoke permission (`allowed_triggers`).
- `iam.tf` — the gateway's service role with two inline policies: invoke-interceptor and bedrock-inference (Bedrock runtime `bedrock:InvokeModel*` + Mantle `bedrock-mantle:CreateInference`/`Get*`/`List*`); its trust policy (in `data.tf`) carries confused-deputy conditions.
- `locals.tf` / `data.tf` — every local and data source lives here (per-directory convention, also in `environments/dev`): caller identity/region/partition as `local.aws_account_id` etc., the inference target request payloads, IAM policy documents, and the endpoint VPC lookup.

The interceptor (`modules/agentcore-gateway/src/interceptor/handler.py`) is a deliberate pass-through: it logs the full event, then returns the documented no-op output — `{"interceptorOutputVersion": "1.0", ...}` with `transformedGatewayRequest`/`transformedGatewayResponse` per the MCP and HTTP contracts in the devguide's "Types of interceptors". Echoing the raw event back is rejected by the gateway ("Received invalid response from interceptor"), and returning a `transformedGatewayResponse` from the REQUEST point short-circuits the target call.

## Constraints

- AWS provider `>= 6.55.0`; lambda module `>= 7.0.0`. Terraform `>= 1.10.0` in `environments/dev` (the S3 backend's `use_lockfile` needs it); the module itself only needs `>= 1.5.0`.
- Applies require a recent AWS CLI v2 with credentials for the target account — inference targets are created through `aws bedrock-agentcore-control`, outside Terraform's providers.
- PrivateLink adds private access but the gateway's public endpoint cannot be disabled; enforcing VPC-only access requires IAM conditions (e.g. `aws:SourceVpce`) on callers.
- Default inbound auth is `AWS_IAM`; `CUSTOM_JWT` requires `jwt_authorizer` (enforced by variable validation in `modules/agentcore-gateway/variables.tf`).
- MCP tool targets (`aws_bedrockagentcore_gateway_target`) are intentionally out of scope for the module — add them in the consuming configuration.
- Inference routing: clients pin a provider by prefixing the model with the target name (`bedrock-mantle/...` or `bedrock-runtime/...`); unqualified model IDs are matched across targets. The gateway rejects model IDs containing `:` ("Model ID contains invalid characters"), so versioned Bedrock IDs (`...-v1:0`) cannot be used — send colon-free forms.
- Known AWS-side gap: the `bedrock-runtime` target creates but cannot be invoked — the gateway signs with a SigV4 service Bedrock rejects, and inference targets on MCP gateways reject every alternative credential type (`iamCredentialProvider`, `API_KEY`, passthrough). The documented provider-target pattern uses the Bedrock Mantle endpoint (`bedrock-mantle.<region>.api.aws`) instead — see the devguide "Inference provider targets" page before changing target auth.
