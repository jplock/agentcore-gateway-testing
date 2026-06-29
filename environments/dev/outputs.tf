output "gateway_id" {
  description = "AgentCore Gateway ID."
  value       = module.agentcore_gateway.gateway_id
}

output "gateway_arn" {
  description = "AgentCore Gateway ARN."
  value       = module.agentcore_gateway.gateway_arn
}

output "gateway_url" {
  description = "MCP endpoint URL for the gateway."
  value       = module.agentcore_gateway.gateway_url
}

output "workload_identity_arn" {
  description = "Standalone AgentCore workload identity ARN."
  value       = module.agentcore_gateway.workload_identity_arn
}

output "gateway_workload_identity_arn" {
  description = "Workload identity ARN managed by the gateway itself."
  value       = module.agentcore_gateway.gateway_workload_identity_arn
}

output "interceptor_lambda_arn" {
  description = "Echo interceptor Lambda ARN."
  value       = module.agentcore_gateway.interceptor_lambda_arn
}

output "interceptor_log_group_name" {
  description = "CloudWatch log group for the interceptor Lambda."
  value       = module.agentcore_gateway.interceptor_log_group_name
}
