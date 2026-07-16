############################################
# Private access to the gateway (AWS PrivateLink)
############################################
# Interface endpoint for the AgentCore Gateway data plane, with private DNS so
# the gateway's default hostname resolves inside the VPC. The gateway's public
# endpoint remains reachable; restrict callers with IAM conditions (e.g.
# aws:SourceVpce) to enforce VPC-only access.

resource "aws_security_group" "gateway_endpoint" {
  name        = "${var.name}-gateway-endpoint"
  description = "HTTPS to the ${var.name} AgentCore Gateway VPC endpoint"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "gateway_endpoint_https" {
  security_group_id = aws_security_group.gateway_endpoint.id
  description       = "HTTPS from the VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.gateway_endpoint.cidr_block
}

resource "aws_vpc_endpoint" "gateway" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.aws_region}.bedrock-agentcore.gateway"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.gateway_endpoint.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.name}-gateway" })
}
