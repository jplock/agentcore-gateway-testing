provider "aws" {
  region = var.region
  # `null` means "no profile, use env-var creds". Locally this resolves to
  # the SSO profile via the variable's default; CI sets TF_VAR_aws_profile="".
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = merge(
      {
        Environment = "dev"
        Project     = "agentcore-gateway-testing"
        Terraform   = "true"
      },
      var.tags,
    )
  }
}
