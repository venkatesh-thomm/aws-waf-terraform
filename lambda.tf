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
# ALERT LAMBDA → SQS PERMISSION
# ============================================================

resource "aws_iam_role_policy" "waf_lambda_sqs" {
  name = "waf-lab-alert-lambda-sqs"
  role = aws_iam_role.waf_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:SendMessage"
        ]

        Resource = aws_sqs_queue.waf_alerts.arn
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
# Receive the WAF event and put the important information into SQS.
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
      SQS_QUEUE_URL = aws_sqs_queue.waf_alerts.url
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


# ============================================================
# PROCESSOR LAMBDA IAM ROLE
# ============================================================

resource "aws_iam_role" "waf_processor_role" {
  name = "waf-lab-processor-lambda-role"

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
    Name = "waf-lab-processor-lambda-role"
  })
}

# ============================================================
# PROCESSOR LAMBDA → CLOUDWATCH LOGS
# ============================================================

resource "aws_iam_role_policy" "waf_processor_logs" {
  name = "waf-lab-processor-logs"
  role = aws_iam_role.waf_processor_role.id

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
# PROCESSOR LAMBDA → SQS
# ============================================================

resource "aws_iam_role_policy" "waf_processor_sqs" {
  name = "waf-lab-processor-sqs"
  role = aws_iam_role.waf_processor_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]

        Resource = aws_sqs_queue.waf_alerts.arn
      }
    ]
  })
}


# ============================================================
# PROCESSOR LAMBDA → SNS
# ============================================================

resource "aws_iam_role_policy" "waf_processor_sns" {
  name = "waf-lab-processor-sns"
  role = aws_iam_role.waf_processor_role.id

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


data "archive_file" "waf_processor_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/waf_processor.py"
  output_path = "${path.module}/lambda/waf_processor.zip"
}

resource "aws_lambda_function" "waf_processor" {
  function_name = "waf-lab-alert-processor"

  role = aws_iam_role.waf_processor_role.arn

  runtime = "python3.12"
  handler = "waf_processor.lambda_handler"

  filename         = data.archive_file.waf_processor_lambda.output_path
  source_code_hash = data.archive_file.waf_processor_lambda.output_base64sha256

  timeout = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.waf_alerts.arn
    }
  }

  tags = merge(local.common_tags, {
    Name = "waf-lab-alert-processor"
  })
}


resource "aws_lambda_event_source_mapping" "waf_sqs" {
  event_source_arn = aws_sqs_queue.waf_alerts.arn

  function_name = aws_lambda_function.waf_processor.arn

  batch_size = 1

  enabled = true
}
