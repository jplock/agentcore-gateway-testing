# agentcore-gateway

Terraform module that provisions an **Amazon Bedrock AgentCore Gateway** that is
privately reachable from a VPC, runs model inference against Amazon Bedrock, and
echoes traffic through a Python **interceptor Lambda**.

The module is deliberately opinionated: everything useful is enabled with sane
defaults, and only identity, auth, and network placement are configurable.

## What it creates

| Resource | Purpose |
| --- | --- |
| `aws_bedrockagentcore_gateway` | MCP gateway with semantic tool search, stateful MCP sessions (1-hour absolute timeout), response streaming (SSE), DEBUG exception level, and the echo interceptor wired at REQUEST/RESPONSE. |
| `aws_vpc_endpoint` + security group | Interface endpoint (`com.amazonaws.<region>.bedrock-agentcore.gateway`) with private DNS so the gateway data plane is reachable privately from your VPC. |
| `terraform_data.inference_target` (×2) | Inference targets served at the gateway's `/inference` path: the `bedrock-mantle` connector and a `bedrock-runtime` provider target (OpenAI-compatible chat completions, all models). |
| CloudWatch log deliveries | Vended log delivery of `APPLICATION_LOGS` to CloudWatch log groups (14-day retention) and `TRACES` to X-Ray, for both the gateway and its workload identity. Traces require account-level CloudWatch Transaction Search, enabled by the consuming configuration. |
| `module.interceptor_lambda` (`terraform-aws-modules/lambda/aws`) | Python echo interceptor (python3.13, 128 MB, 30 s timeout, 14-day logs) including its execution role, log group, and gateway invoke permission. |
| `aws_iam_role` (gateway) | Service role assumed by the gateway, allowed to invoke the interceptor and to run Bedrock runtime / Bedrock Mantle inference. |

The interceptor (`src/interceptor/handler.py`) logs the full event it receives
and returns the payload unchanged, so it is a no-op pass-through that is handy
for inspecting exactly what the gateway sends.

## Usage

```hcl
module "gateway" {
  source = "../../modules/agentcore-gateway"

  name        = "my-agentcore-gw"
  description = "Dev AgentCore gateway"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-...", "subnet-..."]

  # Default is AWS_IAM auth. For JWT instead:
  # authorizer_type = "CUSTOM_JWT"
  # jwt_authorizer = {
  #   discovery_url    = "https://example.auth0.com/.well-known/openid-configuration"
  #   allowed_audience = ["my-audience"]
  # }

  tags = {
    Environment = "dev"
  }
}
```

## Model inference

Clients send OpenAI- or Anthropic-compatible requests to the gateway's
`/inference` path (see the `gateway_inference_url` output). Routing is by the
`model` field; qualify with a target name to pin a provider:

- `bedrock-mantle/<model>` — Bedrock Mantle (OpenAI Responses/Chat Completions
  and Anthropic Messages APIs).
- `bedrock-runtime/<model>` — the regional Bedrock runtime endpoint via its
  OpenAI-compatible chat completions API.

The AWS provider cannot manage inference targets yet
([hashicorp/terraform-provider-aws#48705](https://github.com/hashicorp/terraform-provider-aws/issues/48705)),
so they are created and deleted by `scripts/inference-target.sh` through
`terraform_data` provisioners. Applies therefore need a recent **AWS CLI v2**
on the machine running Terraform, authenticated against the same account.

## Private access

The interface VPC endpoint gives the VPC private access to the gateway data
plane, and private DNS resolves the gateway's default hostname inside the VPC.
The gateway's public endpoint still exists — AWS does not yet support disabling
it — so to enforce VPC-only access, add IAM conditions (e.g. `aws:SourceVpce`)
to the policies of the principals allowed to invoke the gateway.

## Requirements

- Terraform >= 1.5.0
- AWS provider >= 6.55.0
- `terraform-aws-modules/lambda/aws` >= 7.0.0
- A recent AWS CLI v2 on the machine running Terraform (inference targets)

## Notes

- MCP tool targets (`aws_bedrockagentcore_gateway_target` — Lambda, OpenAPI,
  MCP server) are intentionally out of scope — add them in the consuming
  configuration once you know which tools the gateway should expose. Because
  sessions are enabled, targets must not list `Mcp-Session-Id` in their
  `metadata_configuration` header propagation — the gateway manages session IDs
  and rejects such targets with a 400.

<!-- Inputs/Outputs: see variables.tf and outputs.tf -->
