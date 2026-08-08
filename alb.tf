
# Create an Application Load Balancer (ALB)
resource "aws_lb" "application" {
  name               = "waf-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = merge(local.common_tags, {
    Name = "waf-alb"
  })
}

# Create ALB listeners for HTTP and HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect" # Redirect HTTP to HTTPS no fixed response

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Create an HTTPS listener for the ALB
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.application.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate.website.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apache.arn
  }

  depends_on = [
    aws_acm_certificate_validation.website
  ]
}

# Target group for WAF
resource "aws_lb_target_group" "apache" {
  name     = "waf-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }

  tags = merge(local.common_tags, {
    Name = "waf-target-group"
  })
}

# Attach EC2 instances to the target group
resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.apache.arn
  target_id        = aws_instance.waf_instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.apache.arn
  target_id        = aws_instance.waf_instance_2.id
  port             = 80
}
