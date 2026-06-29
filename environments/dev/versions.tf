terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.22.0"
    }
  }

  # Configure a remote backend for real use, e.g.:
  # backend "s3" {
  #   bucket = "my-terraform-state"
  #   key    = "agentcore-gateway/dev/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "agentcore-gateway-testing"
      ManagedBy   = "terraform"
    }
  }
}
