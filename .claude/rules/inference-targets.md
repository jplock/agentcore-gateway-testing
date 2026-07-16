---
paths:
  - "modules/agentcore-gateway/inference.tf"
  - "modules/agentcore-gateway/scripts/**"
---

# Inference targets (CLI workaround)

The `bedrock-mantle` and `bedrock-runtime` gateway targets are managed by `terraform_data` + local-exec calling `scripts/inference-target.sh`, because `aws_bedrockagentcore_gateway_target` has no inference support yet (hashicorp/terraform-provider-aws#48705). Replace this with native resources when that lands.

- Target config changes force replacement via `triggers_replace`; the destroy provisioner may only reference `self.input` (never `path.module`, vars, or other resources).
- The script's inputs are environment variables (`TARGET_REGION`, `GATEWAY_ID`, `TARGET_NAME`, `REQUEST_JSON`); it creates, waits for READY, and deletes with polling so gateway destroy doesn't race in-flight targets.
- Lint after changing the script:
  ```bash
  shellcheck modules/agentcore-gateway/scripts/inference-target.sh
  shfmt -i 2 -d modules/agentcore-gateway/scripts/inference-target.sh
  ```
- These targets live outside Terraform state, so `terraform plan` cannot detect their drift. Inspect them with `aws bedrock-agentcore-control list-gateway-targets --gateway-identifier <gateway-id>`.
