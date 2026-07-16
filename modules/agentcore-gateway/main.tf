############################################
# AgentCore Gateway
############################################

resource "aws_bedrockagentcore_gateway" "this" {
  name        = var.name
  description = var.description
  role_arn    = aws_iam_role.gateway.arn

  protocol_type   = "MCP"
  authorizer_type = var.authorizer_type

  # Verbose error details in gateway responses.
  exception_level = "DEBUG"

  kms_key_arn = var.kms_key_arn

  # Inbound JWT authorization (only when CUSTOM_JWT is selected).
  dynamic "authorizer_configuration" {
    for_each = var.authorizer_type == "CUSTOM_JWT" ? [var.jwt_authorizer] : []
    content {
      custom_jwt_authorizer {
        discovery_url    = authorizer_configuration.value.discovery_url
        allowed_audience = authorizer_configuration.value.allowed_audience
        allowed_clients  = authorizer_configuration.value.allowed_clients
        allowed_scopes   = authorizer_configuration.value.allowed_scopes
      }
    }
  }

  protocol_configuration {
    mcp {
      # Semantic tool search across targets.
      search_type = "SEMANTIC"

      # Stateful MCP sessions (Mcp-Session-Id), scoped to the caller identity.
      # The timeout is absolute, measured from the first initialize request.
      # Sessions plus streaming enable MCP elicitation and sampling.
      session_configuration {
        session_timeout_in_seconds = 3600
      }

      # SSE streaming, required for streamed inference responses.
      streaming_configuration {
        enable_response_streaming = true
      }
    }
  }

  # Echo interceptor on both directions, including request headers.
  interceptor_configuration {
    interception_points = ["REQUEST", "RESPONSE"]

    interceptor {
      lambda {
        arn = module.interceptor_lambda.lambda_function_arn
      }
    }

    input_configuration {
      pass_request_headers = true
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.gateway_invoke_interceptor,
    module.interceptor_lambda,
  ]
}
