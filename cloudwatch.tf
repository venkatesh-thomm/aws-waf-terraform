# CloudWatch Dashboard for WAF
resource "aws_cloudwatch_dashboard" "waf_dashboard" {
  dashboard_name = "waf-lab-dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # WAF BLOCKED
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "WAF - Blocked Requests"
          region = "us-east-1"
          view   = "timeSeries"

          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/WAFV2",
              "BlockedRequests",
              "WebACL",
              aws_wafv2_web_acl.alb_waf.name,
              "Rule",
              "ALL",
              "Region",
              "us-east-1"
            ]
          ]
        }
      },

      # WAF ALLOWED
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "WAF - Allowed Requests"
          region = "us-east-1"
          view   = "timeSeries"

          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/WAFV2",
              "AllowedRequests",
              "WebACL",
              aws_wafv2_web_acl.alb_waf.name,
              "Rule",
              "ALL",
              "Region",
              "us-east-1"
            ]
          ]
        }
      },

      # ALB REQUESTS
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "ALB - Request Count"
          region = "us-east-1"
          view   = "timeSeries"

          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.application.arn_suffix
            ]
          ]
        }
      },

      # ALB 4XX
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "ALB - HTTP 4xx"
          region = "us-east-1"
          view   = "timeSeries"

          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_4XX_Count",
              "LoadBalancer",
              aws_lb.application.arn_suffix
            ]
          ]
        }
      },

      # ALB 5XX
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "ALB - HTTP 5xx"
          region = "us-east-1"
          view   = "timeSeries"

          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              aws_lb.application.arn_suffix
            ]
          ]
        }
      },

      # TARGET 5XX
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "Target - HTTP 5xx"
          region = "us-east-1"
          view   = "timeSeries"

          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "LoadBalancer",
              aws_lb.application.arn_suffix
            ]
          ]
        }
      }
    ]
  })
}
