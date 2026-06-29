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

variable "tags" {
  description = "Additional tags applied to taggable resources."
  type        = map(string)
  default     = {}
}
