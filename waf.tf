# WAF Configuration for block specific IP addresses and monitor blocked requests
resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "waf-blocked-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [
    "103.187.217.248/32"
  ]

  tags = merge(local.common_tags, {
    Name = "waf-blocked-ips"
  })
}

# WAF Web ACL Configuration for ALB
resource "aws_wafv2_web_acl" "alb_waf" {
  name  = "waf-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "block-my-ip"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-my-ip"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-web-acl"
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, {
    Name = "waf-web-acl"
  })
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.application.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf.arn
}


resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-waf-web-acl"
  retention_in_days = 1 # log retention period in days in odd  value 

  tags = {
    Name = "waf-web-acl-logs"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "waf" {
  resource_arn = aws_wafv2_web_acl.alb_waf.arn

  log_destination_configs = [
    aws_cloudwatch_log_group.waf.arn
  ]
}
