resource "aws_instance" "waf_instance_1" {
  ami           = data.aws_ami.joindevops.id
  instance_type = var.instance_type
  #key_name      = var.key_name

  subnet_id = aws_subnet.public_1.id

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = <<-EOF
    #!/bin/bash

    dnf install -y httpd

    systemctl enable httpd
    systemctl start httpd

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

  subnet_id = aws_subnet.public_2.id

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = <<-EOF
    #!/bin/bash

    dnf install -y httpd

    systemctl enable httpd
    systemctl start httpd

    echo "<h1>Hello from waf-instance-2</h1>" > /var/www/html/index.html
  EOF

  tags = merge(local.common_tags, {
    Name = "waf-web-server-2"
  })
}
