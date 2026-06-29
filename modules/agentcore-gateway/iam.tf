data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
  partition  = data.aws_partition.current.partition
}

############################################
# Gateway service role
############################################
# The interceptor Lambda's execution role and CloudWatch Logs policy are
# managed by the terraform-aws-modules/lambda/aws module (see lambda.tf).

data "aws_iam_policy_document" "gateway_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock-agentcore.amazonaws.com"]
    }
    # Confused-deputy protection: only this account's gateways may assume it.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${local.partition}:bedrock-agentcore:${local.region}:${local.account_id}:gateway/*"]
    }
  }
}

resource "aws_iam_role" "gateway" {
  name               = "${var.name}-gateway"
  assume_role_policy = data.aws_iam_policy_document.gateway_assume_role.json
  tags               = var.tags
}

# Allow the gateway to invoke the interceptor Lambda.
resource "aws_iam_role_policy" "gateway_invoke_interceptor" {
  name = "invoke-interceptor"
  role = aws_iam_role.gateway.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = module.interceptor_lambda.lambda_function_arn
      },
    ]
  })
}
