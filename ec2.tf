resource "aws_instance" "waf_instance_1" {
  ami           = data.aws_ami.joindevops.id
  instance_type = var.instance_type
  #key_name      = var.key_name

  subnet_id            = aws_subnet.public_1.id
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = <<-EOF
    #!/bin/bash

    dnf install -y httpd

    systemctl enable httpd
    systemctl start httpd
    dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    echo "<h1>Hello from waf-instance-1</h1>" > /var/www/html/index.html
  EOF

  tags = merge(local.common_tags, {
    Name = "waf-web-server-1"
  })
}

resource "aws_instance" "waf_instance_2" {
  ami           = data.aws_ami.joindevops.id
  instance_type = var.instance_type
  #key_name      = var.key_name

  subnet_id            = aws_subnet.public_2.id
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = <<-EOF
    #!/bin/bash

    dnf install -y httpd
    dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    systemctl enable httpd
    systemctl start httpd

    echo "<h1>Hello from waf-instance-2</h1>" > /var/www/html/index.html
  EOF

  tags = merge(local.common_tags, {
    Name = "waf-web-server-2"
  })
}
