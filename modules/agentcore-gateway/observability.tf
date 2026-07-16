############################################
# Gateway observability (logs + traces)
############################################
# The gateway emits APPLICATION_LOGS and TRACES through CloudWatch vended log
# delivery: a delivery source per log type on the gateway ARN, connected to a
# CloudWatch Logs destination (logs) and an X-Ray destination (traces). Traces
# require account-level CloudWatch Transaction Search, which is enabled by the
# consuming configuration (see environments/dev/observability.tf); spans land
# in the aws/spans log group.

resource "aws_cloudwatch_log_group" "gateway" {
  name              = "/aws/vendedlogs/bedrock-agentcore/gateway/APPLICATION_LOGS/${var.name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_delivery_source" "gateway_logs" {
  name         = "${var.name}-gateway-logs"
  log_type     = "APPLICATION_LOGS"
  resource_arn = aws_bedrockagentcore_gateway.this.gateway_arn
  tags         = var.tags
}

resource "aws_cloudwatch_log_delivery_destination" "gateway_logs" {
  name = "${var.name}-gateway-logs"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.gateway.arn
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_delivery" "gateway_logs" {
  delivery_source_name     = aws_cloudwatch_log_delivery_source.gateway_logs.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.gateway_logs.arn
  tags                     = var.tags
}

resource "aws_cloudwatch_log_delivery_source" "gateway_traces" {
  name         = "${var.name}-gateway-traces"
  log_type     = "TRACES"
  resource_arn = aws_bedrockagentcore_gateway.this.gateway_arn
  tags         = var.tags
}

resource "aws_cloudwatch_log_delivery_destination" "gateway_traces" {
  name                      = "${var.name}-gateway-traces"
  delivery_destination_type = "XRAY"
  tags                      = var.tags
}

resource "aws_cloudwatch_log_delivery" "gateway_traces" {
  delivery_source_name     = aws_cloudwatch_log_delivery_source.gateway_traces.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.gateway_traces.arn
  tags                     = var.tags
}

############################################
# Workload identity observability
############################################
# The gateway's associated workload identity emits its own APPLICATION_LOGS
# and TRACES (the "Identity" tab of the console's log deliveries pane). Traces
# reuse the X-Ray delivery destination above.

resource "aws_cloudwatch_log_group" "workload_identity" {
  name              = "/aws/vendedlogs/bedrock-agentcore/workload-identity/APPLICATION_LOGS/${var.name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_delivery_source" "identity_logs" {
  name         = "${var.name}-identity-logs"
  log_type     = "APPLICATION_LOGS"
  resource_arn = aws_bedrockagentcore_gateway.this.workload_identity_details[0].workload_identity_arn
  tags         = var.tags
}

resource "aws_cloudwatch_log_delivery_destination" "identity_logs" {
  name = "${var.name}-identity-logs"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.workload_identity.arn
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_delivery" "identity_logs" {
  delivery_source_name     = aws_cloudwatch_log_delivery_source.identity_logs.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.identity_logs.arn
  tags                     = var.tags
}

resource "aws_cloudwatch_log_delivery_source" "identity_traces" {
  name         = "${var.name}-identity-traces"
  log_type     = "TRACES"
  resource_arn = aws_bedrockagentcore_gateway.this.workload_identity_details[0].workload_identity_arn
  tags         = var.tags
}

resource "aws_cloudwatch_log_delivery" "identity_traces" {
  delivery_source_name     = aws_cloudwatch_log_delivery_source.identity_traces.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.gateway_traces.arn
  tags                     = var.tags
}
