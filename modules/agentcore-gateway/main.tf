############################################
# AgentCore Identity (standalone workload identity)
############################################

resource "aws_bedrockagentcore_workload_identity" "this" {
  count = var.create_workload_identity ? 1 : 0

  name                                = "${replace(var.name, "-", "_")}_identity"
  allowed_resource_oauth2_return_urls = var.workload_identity_oauth2_return_urls
}

############################################
# AgentCore Gateway
############################################

resource "aws_bedrockagentcore_gateway" "this" {
  name        = var.name
  description = var.description
  role_arn    = aws_iam_role.gateway.arn

  protocol_type   = "MCP"
  authorizer_type = var.authorizer_type

  kms_key_arn = var.kms_key_arn

  # Inbound JWT authorization (only when CUSTOM_JWT is selected).
  dynamic "authorizer_configuration" {
    for_each = var.authorizer_type == "CUSTOM_JWT" ? [var.jwt_authorizer] : []
    content {
      custom_jwt_authorizer {
        discovery_url    = authorizer_configuration.value.discovery_url
        allowed_audience = authorizer_configuration.value.allowed_audience
        allowed_clients  = authorizer_configuration.value.allowed_clients
      }
    }
  }

  # MCP protocol options (only emitted when something is configured).
  dynamic "protocol_configuration" {
    for_each = (var.mcp_instructions != null || var.mcp_supported_versions != null) ? [1] : []
    content {
      mcp {
        instructions       = var.mcp_instructions
        supported_versions = var.mcp_supported_versions
      }
    }
  }

  # Echo interceptor wired in at the configured interception points.
  interceptor_configuration {
    interception_points = var.interception_points

    interceptor {
      lambda {
        arn = module.interceptor_lambda.lambda_function_arn
      }
    }

    input_configuration {
      pass_request_headers = var.pass_request_headers
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.gateway_invoke_interceptor,
    module.interceptor_lambda,
  ]
}
