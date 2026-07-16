# dev environment

Deploys the [`agentcore-gateway`](../../modules/agentcore-gateway) module into a
development account: a minimal VPC (two private subnets, no NAT/IGW), an Amazon
Bedrock AgentCore Gateway reachable privately from that VPC, Bedrock
runtime/Mantle inference targets, and a Python echo interceptor Lambda.

## Usage

```bash
cd environments/dev

# Optionally seed your own values
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan
terraform apply
```

Applies need a recent **AWS CLI v2** — the inference targets are created via
`aws bedrock-agentcore-control` because the Terraform provider cannot manage
them yet.

By default the gateway uses `AWS_IAM` inbound auth, so no external identity
provider is required to stand it up. Set `authorizer_type = "CUSTOM_JWT"` and
provide `jwt_authorizer` to use a JWT-based authorizer instead.

## After apply

Tail the interceptor logs to watch requests/responses echoed by the gateway:

```bash
aws logs tail "$(terraform output -raw interceptor_log_group_name)" --follow
```

Test model inference from a host inside the VPC (traffic resolves to the VPC
endpoint via private DNS). With `AWS_IAM` auth, sign requests with SigV4, e.g.
using [awscurl](https://github.com/okigan/awscurl):

```bash
awscurl --service bedrock-agentcore --region us-east-1 -X POST \
  "$(terraform output -raw gateway_inference_url)/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"model": "bedrock-runtime/us.anthropic.claude-sonnet-4-6", "messages": [{"role": "user", "content": "Hello!"}]}'
```

Prefix the model with `bedrock-mantle/` or `bedrock-runtime/` to pick the
inference target.

> **Note:** the gateway's public endpoint also remains reachable; the VPC
> endpoint adds private access, and IAM conditions (e.g. `aws:SourceVpce`) are
> needed to enforce VPC-only access. Configure a remote backend (see
> `versions.tf`) before using this in a shared/team setting — the default uses
> local state.
