############################################
# Inference targets (Bedrock runtime + Bedrock Mantle)
############################################
# aws_bedrockagentcore_gateway_target does not support inference target
# configurations yet (hashicorp/terraform-provider-aws#48705), so these targets
# are managed through the AWS CLI by scripts/inference-target.sh. Replace this
# with native resources once provider support lands.

locals {
  inference_target_requests = {
    bedrock-mantle = {
      gatewayIdentifier = aws_bedrockagentcore_gateway.this.gateway_id
      name              = "bedrock-mantle"
      description       = "Bedrock Mantle inference connector"
      targetConfiguration = {
        inference = { connector = { source = { connectorId = "bedrock-mantle" } } }
      }
      credentialProviderConfigurations = [{ credentialProviderType = "GATEWAY_IAM_ROLE" }]
    }

    bedrock-runtime = {
      gatewayIdentifier = aws_bedrockagentcore_gateway.this.gateway_id
      name              = "bedrock-runtime"
      description       = "Bedrock runtime inference provider (OpenAI-compatible chat completions)"
      targetConfiguration = {
        inference = {
          provider = {
            endpoint = "https://bedrock-runtime.${local.aws_region}.amazonaws.com"
            operations = [{
              path         = "/v1/chat/completions"
              providerPath = "/openai/v1/chat/completions"
              models       = [{ model = "*" }]
            }]
          }
        }
      }
      credentialProviderConfigurations = [{ credentialProviderType = "GATEWAY_IAM_ROLE" }]
    }
  }
}

resource "terraform_data" "inference_target" {
  for_each = local.inference_target_requests

  input = {
    script       = "${path.module}/scripts/inference-target.sh"
    region       = local.aws_region
    gateway_id   = aws_bedrockagentcore_gateway.this.gateway_id
    name         = each.key
    request_json = jsonencode(each.value)
  }

  triggers_replace = [
    aws_bedrockagentcore_gateway.this.gateway_id,
    jsonencode(each.value),
  ]

  provisioner "local-exec" {
    command = "${self.input.script} create"
    environment = {
      TARGET_REGION = self.input.region
      GATEWAY_ID    = self.input.gateway_id
      TARGET_NAME   = self.input.name
      REQUEST_JSON  = self.input.request_json
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.input.script} delete"
    environment = {
      TARGET_REGION = self.input.region
      GATEWAY_ID    = self.input.gateway_id
      TARGET_NAME   = self.input.name
    }
  }

  depends_on = [aws_iam_role_policy.gateway_inference]
}
