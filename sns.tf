resource "aws_sns_topic" "waf_alerts" {
  name = "waf-lab-alerts"

  tags = merge(local.common_tags, {
    Name = "waf-lab-alerts"
  })
}

resource "aws_sns_topic_subscription" "waf_email" {
  topic_arn = aws_sns_topic.waf_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
