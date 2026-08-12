
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


# ============================================================
# VPC FLOW LOGS - CLOUDWATCH LOG GROUP
# ============================================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs"
  retention_in_days = 1 # Set retention to 1 day for testing purposes. Adjust as needed for production.

  tags = merge(local.common_tags, {
    Name = "vpc-flow-logs"
  })
}


# ============================================================
# IAM ROLE FOR VPC FLOW LOGS
# ============================================================

resource "aws_iam_role" "vpc_flow_logs" {
  name = "waf-lab-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "waf-lab-vpc-flow-logs-role"
  })
}


# ============================================================
# LEAST-PRIVILEGE  IAM ROLE POLICY FOR VPC FLOW LOGS
# ============================================================

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "waf-lab-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      }
    ]
  })
}

# ============================================================
# VPC FLOW LOG
# ============================================================

resource "aws_flow_log" "vpc" {
  vpc_id = aws_vpc.main.id

  traffic_type = "ALL"

  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn

  tags = merge(local.common_tags, {
    Name = "waf-lab-vpc-flow-logs"
  })
}
