# dev environment

Deploys the [`agentcore-gateway`](../../modules/agentcore-gateway) module into a
development account: an Amazon Bedrock AgentCore Gateway and a Python echo
interceptor Lambda (deployed via `terraform-aws-modules/lambda/aws`).

## Usage

```bash
cd environments/dev

# Optionally seed your own values
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan
terraform apply
```

By default the gateway uses `AWS_IAM` inbound auth, so no external identity
provider is required to stand it up. Set `authorizer_type = "CUSTOM_JWT"` and
provide `jwt_authorizer` to use a JWT-based authorizer instead.

## After apply

Tail the interceptor logs to watch requests/responses echoed by the gateway:

```bash
aws logs tail "$(terraform output -raw interceptor_log_group_name)" --follow
```

> **Note:** configure a remote backend (see `versions.tf`) before using this in
> a shared/team setting — the default uses local state.
