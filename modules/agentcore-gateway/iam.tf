############################################
# Gateway service role
############################################
# The interceptor Lambda's execution role and CloudWatch Logs policy are
# managed by the terraform-aws-modules/lambda/aws module (see lambda.tf).

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
