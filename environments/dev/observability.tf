############################################
# CloudWatch Transaction Search (account-level)
############################################
# One-time account/region enablement required before AgentCore trace delivery
# to X-Ray works. Spans are ingested as structured logs into the aws/spans log
# group. These are account settings: removing them from Terraform does not
# turn them back off.

resource "aws_cloudwatch_log_resource_policy" "transaction_search" {
  policy_name     = "${var.name}-transaction-search"
  policy_document = data.aws_iam_policy_document.transaction_search.json
}

resource "aws_xray_trace_segment_destination" "cloudwatch_logs" {
  destination = "CloudWatchLogs"

  depends_on = [aws_cloudwatch_log_resource_policy.transaction_search]
}

# Index every trace so all gateway traffic is searchable; lower this
# percentage in accounts where span ingestion cost matters.
resource "aws_xray_indexing_rule" "default" {
  name = "Default"

  rule {
    probabilistic {
      desired_sampling_percentage = 100
    }
  }

  depends_on = [aws_xray_trace_segment_destination.cloudwatch_logs]
}
