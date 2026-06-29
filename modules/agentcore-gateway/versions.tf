terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # AgentCore Gateway interceptor support landed in 6.22.0 and the
      # workload identity resource in 6.23.0.
      version = ">= 6.23.0"
    }
  }
}
