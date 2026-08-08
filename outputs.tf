output "alb_dns_name" {
  value = aws_lb.application.dns_name
}

output "website_url" {
  value = "http://${var.domain_name}"
}

output "waf_arn" {
  value = aws_wafv2_web_acl.alb_waf.arn
}

