output "gateway_id" {
  description = "The AgentCore Gateway ID."
  value       = aws_bedrockagentcore_gateway.this.gateway_id
}

output "gateway_arn" {
  description = "The AgentCore Gateway ARN."
  value       = aws_bedrockagentcore_gateway.this.gateway_arn
}

output "gateway_url" {
  description = "The MCP endpoint URL for the gateway."
  value       = aws_bedrockagentcore_gateway.this.gateway_url
}

output "gateway_role_arn" {
  description = "ARN of the IAM role assumed by the gateway."
  value       = aws_iam_role.gateway.arn
}

output "interceptor_lambda_arn" {
  description = "ARN of the echo interceptor Lambda function."
  value       = module.interceptor_lambda.lambda_function_arn
}

output "interceptor_lambda_name" {
  description = "Name of the echo interceptor Lambda function."
  value       = module.interceptor_lambda.lambda_function_name
}

output "interceptor_lambda_role_arn" {
  description = "ARN of the interceptor Lambda execution role."
  value       = module.interceptor_lambda.lambda_role_arn
}

output "interceptor_log_group_name" {
  description = "CloudWatch Log group for the interceptor Lambda."
  value       = module.interceptor_lambda.lambda_cloudwatch_log_group_name
}
