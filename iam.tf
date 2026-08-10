# ============================================================
# IAM ROLE FOR EC2 / SSM
# ============================================================

resource "aws_iam_role" "ec2_ssm_role" {
  name = "waf-lab-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "waf-lab-ec2-ssm-role"
  })
}


# ============================================================
# SSM POLICY
# ============================================================

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ============================================================
# EC2 INSTANCE PROFILE
# ============================================================

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "waf-lab-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name

  tags = merge(local.common_tags, {
    Name = "waf-lab-ec2-ssm-profile"
  })
}
