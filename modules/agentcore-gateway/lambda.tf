module "interceptor_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = ">= 7.0.0"

  function_name = "${var.name}-interceptor"
  description   = "Echo interceptor for the ${var.name} AgentCore Gateway"

  handler     = "handler.handler"
  runtime     = var.lambda_runtime
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  # Let the module package the Python source directly.
  source_path = "${path.module}/src/interceptor"

  environment_variables = {
    LOG_LEVEL = var.lambda_log_level
  }

  # IAM execution role + CloudWatch Logs are managed by the module.
  create_role                       = true
  attach_cloudwatch_logs_policy     = true
  cloudwatch_logs_retention_in_days = var.log_retention_in_days

  # Allow the AgentCore Gateway service to invoke the interceptor.
  allowed_triggers = {
    AgentCoreGateway = {
      principal  = "bedrock-agentcore.amazonaws.com"
      source_arn = "arn:${local.partition}:bedrock-agentcore:${local.region}:${local.account_id}:gateway/*"
    }
  }

  tags = var.tags
}
