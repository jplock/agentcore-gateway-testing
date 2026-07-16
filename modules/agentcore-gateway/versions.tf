terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Gateway streaming/session configuration, exception level, and JWT
      # allowed_scopes landed by 6.55.0 (interceptors landed in 6.22.0).
      version = ">= 6.55.0"
    }
  }
}
