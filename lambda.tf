# ============================================================
# LAMBDA IAM ROLE
# ============================================================

resource "aws_iam_role" "waf_lambda_role" {
  name = "waf-lab-alert-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "waf-lab-alert-lambda-role"
  })
}


# ============================================================
# LAMBDA CLOUDWATCH LOGGING PERMISSIONS
# ============================================================

resource "aws_iam_role_policy" "waf_lambda_logs" {
  name = "waf-lab-alert-lambda-logs"
  role = aws_iam_role.waf_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      }
    ]
  })
}


# ============================================================
# LAMBDA SNS PERMISSION
# ============================================================

resource "aws_iam_role_policy" "waf_lambda_sns" {
  name = "waf-lab-alert-lambda-sns"
  role = aws_iam_role.waf_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sns:Publish"
        ]

        Resource = aws_sns_topic.waf_alerts.arn
      }
    ]
  })
}


# ============================================================
# PACKAGE PYTHON CODE
# ============================================================

data "archive_file" "waf_alert_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/waf_alert.py"
  output_path = "${path.module}/lambda/waf_alert.zip"
}


# ============================================================
# LAMBDA FUNCTION
# ============================================================

resource "aws_lambda_function" "waf_alert" {
  function_name = "waf-lab-alert"

  role = aws_iam_role.waf_lambda_role.arn

  runtime = "python3.12"
  handler = "waf_alert.lambda_handler"

  filename         = data.archive_file.waf_alert_lambda.output_path
  source_code_hash = data.archive_file.waf_alert_lambda.output_base64sha256

  timeout = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.waf_alerts.arn
    }
  }

  tags = merge(local.common_tags, {
    Name = "waf-lab-alert"
  })
}


# ============================================================
# ALLOW CLOUDWATCH LOGS TO INVOKE LAMBDA
# ============================================================

resource "aws_lambda_permission" "allow_waf_logs" {
  statement_id = "AllowWAFCloudWatchLogs"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.waf_alert.function_name

  principal = "logs.amazonaws.com"

  source_arn = "${aws_cloudwatch_log_group.waf.arn}:*"

  source_account = data.aws_caller_identity.current.account_id
}

# ============================================================
# CLOUDWATCH LOG SUBSCRIPTION FILTER
# ============================================================

resource "aws_cloudwatch_log_subscription_filter" "waf_blocked" {
  name            = "waf-blocked-request-filter"
  log_group_name  = aws_cloudwatch_log_group.waf.name
  filter_pattern  = "{ $.action = \"BLOCK\" }"
  destination_arn = aws_lambda_function.waf_alert.arn

  depends_on = [
    aws_lambda_permission.allow_waf_logs
  ]
}
