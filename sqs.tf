# ============================================================
# SQS DEAD LETTER QUEUE
# ============================================================

resource "aws_sqs_queue" "waf_alert_dlq" {
  name = "waf-lab-alert-dlq"

  message_retention_seconds = 345600 # 4 days

  tags = merge(local.common_tags, {
    Name = "waf-lab-alert-dlq"
  })
}


# ============================================================
# SQS MAIN QUEUE
# ============================================================

resource "aws_sqs_queue" "waf_alerts" {
  name = "waf-lab-alerts"

  visibility_timeout_seconds = 60

  message_retention_seconds = 345600 # 4 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.waf_alert_dlq.arn
    maxReceiveCount     = 3
  })

  tags = merge(local.common_tags, {
    Name = "waf-lab-alerts"
  })
}
