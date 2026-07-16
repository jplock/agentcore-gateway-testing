---
paths:
  - "**/*.tf"
---

# Terraform conventions

- Bedrock AgentCore is newer than most training data and the provider surface changes release-to-release. Before using a resource or argument, verify it exists at the locked provider version (see `environments/dev/.terraform.lock.hcl`) by reading the docs at that git tag, e.g. `https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/v<version>/website/docs/r/bedrockagentcore_gateway.html.markdown` — not memory, not the latest registry docs.
- Version floors are declared in both `modules/agentcore-gateway/versions.tf` and `environments/dev/versions.tf` — bump them together. The VPC module in `environments/dev` is pinned exactly (`6.6.1`).
- After editing, run `terraform fmt -recursive` from the repo root and `terraform validate` from `environments/dev`.
- The module is deliberately low-variable: only identity, auth, network placement, KMS, and tags are inputs. Don't add variables for new knobs — pick a sane default and hardcode it.
