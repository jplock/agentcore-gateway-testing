data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_iam_policy_document" "transaction_search" {
  statement {
    sid     = "TransactionSearchXRayAccess"
    effect  = "Allow"
    actions = ["logs:PutLogEvents"]

    principals {
      type        = "Service"
      identifiers = ["xray.amazonaws.com"]
    }

    resources = [
      "arn:${local.aws_partition}:logs:${var.region}:${local.aws_account_id}:log-group:aws/spans:*",
      "arn:${local.aws_partition}:logs:${var.region}:${local.aws_account_id}:log-group:/aws/application-signals/data:*",
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${local.aws_partition}:xray:${var.region}:${local.aws_account_id}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }
  }
}
