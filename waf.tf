# ============================================================
# WAF IP SET
# ============================================================

resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "waf-blocked-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [
    "103.187.217.239/32"
  ]

  tags = merge(local.common_tags, {
    Name = "waf-blocked-ips"
  })
}


# ============================================================
# WAF WEB ACL
# ============================================================

resource "aws_wafv2_web_acl" "alb_waf" {
  name  = "waf-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # ----------------------------------------------------------
  # Custom IP Block Rule
  # ----------------------------------------------------------

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

  # ----------------------------------------------------------
  # AWS Managed Common Rule Set
  # ----------------------------------------------------------

  rule {
    name     = "aws-managed-common-rules"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-managed-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # ----------------------------------------------------------
  # AWS Managed Known Bad Inputs Rule Set
  # ----------------------------------------------------------

  rule {
    name     = "aws-managed-known-bad-inputs"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-managed-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # ----------------------------------------------------------
  # WAF Rate Limiting
  # ----------------------------------------------------------

  rule {
    name     = "waf-rate-limit"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-rate-limit"
      sampled_requests_enabled   = true
    }
  }
  # ----------------------------------------------------------
  # WAF WEB ACL VISIBILITY
  # ----------------------------------------------------------

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-web-acl"
    sampled_requests_enabled   = true
  }

  # ----------------------------------------------------------
  # TAGS
  # ----------------------------------------------------------

  tags = merge(local.common_tags, {
    Name = "waf-web-acl"
  })
}


# ============================================================
# WAF → ALB ASSOCIATION
# ============================================================

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.application.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf.arn
}


# ============================================================
# WAF CLOUDWATCH LOG GROUP
# ============================================================

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-waf-web-acl"
  retention_in_days = 1 # Set retention to 1 day for testing purposes. Adjust as needed for production.

  tags = merge(local.common_tags, {
    Name = "waf-web-acl-logs"
  })
}


# ============================================================
# WAF LOGGING CONFIGURATION
# ============================================================

resource "aws_wafv2_web_acl_logging_configuration" "waf" {
  resource_arn = aws_wafv2_web_acl.alb_waf.arn

  log_destination_configs = [
    aws_cloudwatch_log_group.waf.arn
  ]
}
