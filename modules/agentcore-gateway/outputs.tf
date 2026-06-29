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

output "gateway_workload_identity_arn" {
  description = "ARN of the workload identity automatically created and managed by the gateway."
  value       = try(aws_bedrockagentcore_gateway.this.workload_identity_details[0].workload_identity_arn, null)
}

output "workload_identity_arn" {
  description = "ARN of the standalone AgentCore workload identity (null when create_workload_identity is false)."
  value       = try(aws_bedrockagentcore_workload_identity.this[0].workload_identity_arn, null)
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
