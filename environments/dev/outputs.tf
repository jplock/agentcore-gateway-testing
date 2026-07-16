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

output "gateway_inference_url" {
  description = "OpenAI/Anthropic-compatible inference endpoint served by the gateway."
  value       = module.agentcore_gateway.gateway_inference_url
}

output "vpc_id" {
  description = "VPC from which the gateway is privately reachable."
  value       = module.vpc.vpc_id
}

output "gateway_vpc_endpoint_id" {
  description = "Interface VPC endpoint providing private access to the gateway."
  value       = module.agentcore_gateway.gateway_vpc_endpoint_id
}

output "interceptor_lambda_arn" {
  description = "Echo interceptor Lambda ARN."
  value       = module.agentcore_gateway.interceptor_lambda_arn
}

output "interceptor_log_group_name" {
  description = "CloudWatch log group for the interceptor Lambda."
  value       = module.agentcore_gateway.interceptor_log_group_name
}
