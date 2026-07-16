# Minimal VPC for private access to the gateway. Private subnets only; the
# interface VPC endpoint needs no NAT or internet gateway.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = var.name
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  # Required for the endpoint's private DNS names to resolve.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = var.tags
}

module "agentcore_gateway" {
  source = "../../modules/agentcore-gateway"

  name        = var.name
  description = "Dev AgentCore gateway with echo interceptor"

  authorizer_type = var.authorizer_type
  jwt_authorizer  = var.jwt_authorizer

  # Same credentials for the provider and the local-exec inference-target script.
  aws_profile = var.aws_profile

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = var.tags

  # The module's TRACES delivery fails unless Transaction Search is enabled
  # first (observability.tf).
  depends_on = [aws_xray_trace_segment_destination.cloudwatch_logs]
}
