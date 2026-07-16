locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = data.aws_region.current.region
  aws_partition  = data.aws_partition.current.partition
}

# create-gateway-target request payloads for the inference targets managed by
# scripts/inference-target.sh (see inference.tf).
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
