# agentcore-gateway-testing

Terraform for standing up an [Amazon Bedrock AgentCore Gateway](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway.html) with:

- **Private VPC access** — an AWS PrivateLink interface endpoint (`com.amazonaws.<region>.bedrock-agentcore.gateway`) with private DNS, so the gateway data plane is reachable from inside a VPC without traversing the internet.
- **Model inference** — `bedrock-mantle` (OpenAI Responses/Chat Completions and Anthropic Messages APIs) and `bedrock-runtime` (OpenAI-compatible chat completions) targets served at the gateway's `/inference` path.
- **Traffic inspection** — a Python echo interceptor Lambda invoked at REQUEST and RESPONSE that logs every payload flowing through the gateway and returns it unchanged.

## Layout

| Path | Purpose |
| --- | --- |
| [`modules/agentcore-gateway`](modules/agentcore-gateway/README.md) | Reusable module: gateway, VPC endpoint, inference targets, interceptor Lambda, IAM. |
| [`environments/dev`](environments/dev/README.md) | Deployable dev configuration: minimal VPC (private subnets only) plus the module. |

## Quick start

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

See the [dev environment README](environments/dev/README.md) for testing the gateway after apply (tailing interceptor logs, invoking `/inference` from inside the VPC).

## Requirements

- Terraform >= 1.5.0
- AWS provider >= 6.55.0
- A recent AWS CLI v2 on the machine running Terraform — the inference targets are created through `aws bedrock-agentcore-control` because the provider cannot manage them yet ([hashicorp/terraform-provider-aws#48705](https://github.com/hashicorp/terraform-provider-aws/issues/48705))

## Notes

- The gateway's public endpoint cannot be disabled; the VPC endpoint adds private access, and IAM conditions (e.g. `aws:SourceVpce`) are needed to enforce VPC-only access.
- The dev environment uses local Terraform state — configure a remote backend before sharing it.

## License

[MIT-0](LICENSE.md)
