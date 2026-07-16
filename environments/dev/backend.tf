terraform {
  backend "s3" {
    profile      = "dev-admin"
    bucket       = "terraform-state-952961969614-us-east-1-an"
    key          = "agentcore-gateway/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}