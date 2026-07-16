variable "name" {
  description = "Base name used for the gateway, Lambda, and IAM resources. Must be 3-100 chars: alphanumerics, hyphens, periods, underscores."
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
    - allowed_scopes:   Optional set of scopes allowed to access the gateway.
  EOT
  type = object({
    discovery_url    = string
    allowed_audience = optional(list(string))
    allowed_clients  = optional(list(string))
    allowed_scopes   = optional(list(string))
  })
  default = null

  validation {
    condition     = var.authorizer_type != "CUSTOM_JWT" || var.jwt_authorizer != null
    error_message = "jwt_authorizer must be set when authorizer_type is CUSTOM_JWT."
  }
}

variable "vpc_id" {
  description = "VPC from which the gateway is privately reachable. An interface VPC endpoint for the AgentCore Gateway data plane is created here."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the gateway VPC endpoint network interfaces."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must not be empty."
  }
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
