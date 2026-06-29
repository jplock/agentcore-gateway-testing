variable "name" {
  description = "Base name used for the gateway, identity, Lambda, and IAM resources. Must be 3-255 chars: alphanumerics, hyphens, periods, underscores."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]{3,100}$", var.name))
    error_message = "name must be 3-100 characters and contain only alphanumerics, hyphens, periods, and underscores."
  }
}

variable "description" {
  description = "Description applied to the AgentCore Gateway."
  type        = string
  default     = "AgentCore Gateway managed by Terraform"
}

variable "authorizer_type" {
  description = "Inbound authorization method for the gateway. One of CUSTOM_JWT or AWS_IAM."
  type        = string
  default     = "AWS_IAM"

  validation {
    condition     = contains(["CUSTOM_JWT", "AWS_IAM"], var.authorizer_type)
    error_message = "authorizer_type must be either CUSTOM_JWT or AWS_IAM."
  }
}

variable "jwt_authorizer" {
  description = <<-EOT
    JWT authorizer configuration. Required when authorizer_type is CUSTOM_JWT, ignored otherwise.
    - discovery_url:    OpenID Connect discovery (.well-known) endpoint.
    - allowed_audience: Optional set of accepted JWT audiences.
    - allowed_clients:  Optional set of accepted client IDs.
  EOT
  type = object({
    discovery_url    = string
    allowed_audience = optional(list(string))
    allowed_clients  = optional(list(string))
  })
  default = null

  validation {
    condition     = var.authorizer_type != "CUSTOM_JWT" || var.jwt_authorizer != null
    error_message = "jwt_authorizer must be set when authorizer_type is CUSTOM_JWT."
  }
}

variable "mcp_instructions" {
  description = "Optional instructions text exposed to MCP clients via the gateway."
  type        = string
  default     = null
}

variable "mcp_supported_versions" {
  description = "Optional set of MCP protocol versions the gateway advertises. Leave null to use the service default."
  type        = list(string)
  default     = null
}

variable "interception_points" {
  description = "Points at which the interceptor Lambda is invoked. Any of REQUEST, RESPONSE."
  type        = list(string)
  default     = ["REQUEST", "RESPONSE"]

  validation {
    condition = length(var.interception_points) > 0 && alltrue([
      for p in var.interception_points : contains(["REQUEST", "RESPONSE"], p)
    ])
    error_message = "interception_points must be a non-empty subset of [\"REQUEST\", \"RESPONSE\"]."
  }
}

variable "pass_request_headers" {
  description = "Whether the gateway forwards request headers to the interceptor Lambda."
  type        = bool
  default     = true
}

variable "lambda_runtime" {
  description = "Python runtime for the interceptor Lambda."
  type        = string
  default     = "python3.13"
}

variable "lambda_timeout" {
  description = "Timeout (seconds) for the interceptor Lambda."
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Memory (MB) for the interceptor Lambda."
  type        = number
  default     = 128
}

variable "lambda_log_level" {
  description = "LOG_LEVEL environment variable passed to the interceptor Lambda."
  type        = string
  default     = "INFO"
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention for the interceptor Lambda log group."
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt the gateway. Uses an AWS managed key when null."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources that support tagging."
  type        = map(string)
  default     = {}
}
