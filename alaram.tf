resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name        = "waf-lab-blocked-requests"
  alarm_description = "WAF blocked more than 10 requests in 5 minutes"

  namespace   = "AWS/WAFV2"
  metric_name = "BlockedRequests"

  dimensions = {
    WebACL = aws_wafv2_web_acl.alb_waf.name
    Rule   = "ALL"
    Region = "us-east-1"
  }

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"

  alarm_actions = [
    aws_sns_topic.waf_alerts.arn
  ]

  tags = merge(local.common_tags, {
    Name = "waf-lab-blocked-requests-alarm"
  })
}
