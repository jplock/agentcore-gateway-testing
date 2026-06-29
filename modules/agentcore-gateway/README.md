# agentcore-gateway

Terraform module that provisions an **Amazon Bedrock AgentCore Gateway** together
with **AgentCore Identity** (workload identity) and a small Python **interceptor
Lambda** that echoes the requests and responses flowing through the gateway.

## What it creates

| Resource | Purpose |
| --- | --- |
| `aws_bedrockagentcore_gateway` | The MCP gateway, wired to the interceptor Lambda. |
| `aws_bedrockagentcore_workload_identity` | Standalone AgentCore Identity (optional). |
| `module.interceptor_lambda` (`terraform-aws-modules/lambda/aws`) | Python echo interceptor invoked at REQUEST/RESPONSE, including its execution role, CloudWatch log group, and gateway invoke permission. |
| `aws_iam_role` (gateway) | Service role assumed by the gateway, allowed to invoke the interceptor. |

The interceptor (`src/interceptor/handler.py`) logs the full event it receives
and returns the payload unchanged, so it is a no-op pass-through that is handy
for inspecting exactly what the gateway sends.

## Usage

```hcl
module "gateway" {
  source = "../../modules/agentcore-gateway"

  name        = "my-agentcore-gw"
  description = "Dev AgentCore gateway"

  # Default is AWS_IAM auth. For JWT instead:
  # authorizer_type = "CUSTOM_JWT"
  # jwt_authorizer = {
  #   discovery_url    = "https://example.auth0.com/.well-known/openid-configuration"
  #   allowed_audience = ["my-audience"]
  # }

  interception_points = ["REQUEST", "RESPONSE"]

  tags = {
    Environment = "dev"
  }
}
```

## Requirements

- Terraform >= 1.5.0
- AWS provider >= 6.23.0 (AgentCore Gateway interceptors require >= 6.22.0;
  the workload identity resource requires >= 6.23.0)
- `terraform-aws-modules/lambda/aws` >= 7.0.0 (packages and deploys the
  interceptor Lambda; pulls in the `archive`/`local`/`null` providers it needs)

## Notes

- Targets (`aws_bedrockagentcore_gateway_target`) are intentionally out of scope
  for this module — add them in the consuming configuration once you know which
  Lambdas/APIs the gateway should expose as MCP tools.
- `gateway_workload_identity_arn` is the identity the gateway manages for itself;
  `workload_identity_arn` is the separate, standalone identity this module
  creates when `create_workload_identity = true`.

<!-- Inputs/Outputs: see variables.tf and outputs.tf -->
