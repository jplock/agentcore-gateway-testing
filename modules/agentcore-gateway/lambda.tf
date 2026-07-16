module "interceptor_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = ">= 7.0.0"

  function_name = "${var.name}-interceptor"
  description   = "Echo interceptor for the ${var.name} AgentCore Gateway"

  handler     = "handler.handler"
  runtime     = "python3.13"
  timeout     = 30
  memory_size = 128

  # Let the module package the Python source directly.
  source_path = "${path.module}/src/interceptor"

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  # IAM execution role + CloudWatch Logs are managed by the module.
  create_role                       = true
  attach_cloudwatch_logs_policy     = true
  cloudwatch_logs_retention_in_days = 14

  # Allow the AgentCore Gateway service to invoke the interceptor. The gateway
  # calls the unqualified function ARN, so only the unqualified permission is
  # needed; the module's version-qualified permission would fail with
  # "adding policies for $LATEST" because the function is not published.
  allowed_triggers = {
    AgentCoreGateway = {
      principal  = "bedrock-agentcore.amazonaws.com"
      source_arn = "arn:${local.aws_partition}:bedrock-agentcore:${local.aws_region}:${local.aws_account_id}:gateway/*"
    }
  }
  create_current_version_allowed_triggers = false

  tags = var.tags
}
