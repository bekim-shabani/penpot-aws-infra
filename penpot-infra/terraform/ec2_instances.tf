# EC2 Instances Configuration

resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = local.public_subnet
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.backup_profile.name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }
  user_data = <<-EOF
    #!/bin/bash
    set -eux
    mkdir -p /etc/ssh/sshd_config.d
    cat >/etc/ssh/sshd_config.d/port-20100.conf <<'EOC'
    Port 22
    Port 20100
    EOC
    sshd -t
    systemctl restart ssh || systemctl restart sshd
    ss -tulpn | grep -E '(:22|:20100)' || true

    ufw allow 20100/tcp
    ufw --force enable
  EOF

  tags = {
    Name        = var.instance_names["bastion"]
    Environment = var.environment
    Project     = var.project_name
    SubnetType  = "public"
  }
}

resource "aws_instance" "grafana" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = local.private_subnet_1

  vpc_security_group_ids = [aws_security_group.allow_ssh_bastion.id]

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }
  user_data = <<-EOF
      #!/bin/bash
      ufw allow 22/tcp
      ufw --force enable
    EOF

  tags = {
    Name        = var.instance_names["grafana"]
    Environment = var.environment
    Project     = var.project_name
    SubnetType  = "private"
  }
}

resource "aws_instance" "prometheus" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = local.private_subnet_1

  vpc_security_group_ids = [aws_security_group.allow_ssh_bastion.id]

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }
  user_data = <<-EOF
      #!/bin/bash
      ufw allow 22/tcp
      ufw --force enable
    EOF

  tags = {
    Name        = var.instance_names["prometheus"]
    Environment = var.environment
    Project     = var.project_name
    SubnetType  = "private"
  }
}
