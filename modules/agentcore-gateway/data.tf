data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

data "aws_vpc" "gateway_endpoint" {
  id = var.vpc_id
}

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
      values   = [local.aws_account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${local.aws_partition}:bedrock-agentcore:${local.aws_region}:${local.aws_account_id}:gateway/*"]
    }
  }
}

data "aws_iam_policy_document" "gateway_inference" {
  # Mirrors the AmazonBedrockMantleInferenceAccess managed policy, scoped to
  # this account's Mantle projects.
  statement {
    sid = "BedrockMantleInference"
    actions = [
      "bedrock-mantle:CreateInference",
      "bedrock-mantle:Get*",
      "bedrock-mantle:List*",
    ]
    resources = ["arn:${local.aws_partition}:bedrock-mantle:${local.aws_region}:${local.aws_account_id}:project/*"]
  }

  statement {
    sid = "BedrockRuntimeInference"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    # Region wildcard: cross-region inference profiles fan out to models in
    # other regions.
    resources = [
      "arn:${local.aws_partition}:bedrock:*::foundation-model/*",
      "arn:${local.aws_partition}:bedrock:*:${local.aws_account_id}:inference-profile/*",
    ]
  }
}
