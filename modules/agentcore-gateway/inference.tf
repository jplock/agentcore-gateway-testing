############################################
# Inference targets (Bedrock runtime + Bedrock Mantle)
############################################
# aws_bedrockagentcore_gateway_target does not support inference target
# configurations yet (hashicorp/terraform-provider-aws#48705), so these targets
# are managed through the AWS CLI by scripts/inference-target.sh. Replace this
# with native resources once provider support lands.

resource "terraform_data" "inference_target" {
  for_each = local.inference_target_requests

  input = {
    script       = "${path.module}/scripts/inference-target.sh"
    region       = local.aws_region
    profile      = var.aws_profile
    gateway_id   = aws_bedrockagentcore_gateway.this.gateway_id
    name         = each.key
    request_json = jsonencode(each.value)
  }

  triggers_replace = [
    aws_bedrockagentcore_gateway.this.gateway_id,
    jsonencode(each.value),
  ]

  # The AWS CLI runs outside Terraform's provider auth; AWS_PROFILE is set only
  # when a profile is configured so empty values don't mask ambient credentials.
  provisioner "local-exec" {
    command = "${self.input.script} create"
    environment = merge(
      {
        TARGET_REGION = self.input.region
        GATEWAY_ID    = self.input.gateway_id
        TARGET_NAME   = self.input.name
        REQUEST_JSON  = self.input.request_json
      },
      try(self.input.profile, "") == "" ? {} : { AWS_PROFILE = self.input.profile },
    )
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.input.script} delete"
    environment = merge(
      {
        TARGET_REGION = self.input.region
        GATEWAY_ID    = self.input.gateway_id
        TARGET_NAME   = self.input.name
      },
      try(self.input.profile, "") == "" ? {} : { AWS_PROFILE = self.input.profile },
    )
  }

  depends_on = [aws_iam_role_policy.gateway_inference]
}
