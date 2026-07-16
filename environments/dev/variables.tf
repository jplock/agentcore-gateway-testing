variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for the AgentCore gateway and related resources."
  type        = string
  default     = "agentcore-dev"
}

variable "tags" {
  description = "Additional tags merged into the provider's default_tags."
  type        = map(string)
  default     = {}
}

variable "authorizer_type" {
  description = "Inbound authorization method for the gateway (AWS_IAM or CUSTOM_JWT)."
  type        = string
  default     = "AWS_IAM"
}

variable "jwt_authorizer" {
  description = "JWT authorizer config; required only when authorizer_type is CUSTOM_JWT."
  type = object({
    discovery_url    = string
    allowed_audience = optional(list(string))
    allowed_clients  = optional(list(string))
  })
  default = null
}

variable "aws_profile" {
  description = "AWS shared-credentials profile name. Defaults to the local SSO profile; CI sets this to \"\" so the provider falls through to env-var credentials supplied by OIDC."
  type        = string
  default     = "dev-admin"
}