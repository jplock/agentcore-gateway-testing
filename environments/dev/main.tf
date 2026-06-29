module "agentcore_gateway" {
  source = "../../modules/agentcore-gateway"

  name        = var.name
  description = "Dev AgentCore gateway with echo interceptor"

  authorizer_type = var.authorizer_type
  jwt_authorizer  = var.jwt_authorizer

  # Echo both directions through the interceptor Lambda.
  interception_points  = ["REQUEST", "RESPONSE"]
  pass_request_headers = true

  lambda_log_level = "DEBUG"

  tags = var.tags
}
