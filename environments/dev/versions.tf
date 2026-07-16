terraform {
  # The S3 backend's use_lockfile (backend.tf) needs 1.10+.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.55.0"
    }
  }
}
