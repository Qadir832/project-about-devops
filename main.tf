# =====================================================
# TERRAFORM CONFIGURATION
# S3 BACKEND NOT USED - LOCAL STATE
# =====================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =====================================================
# VARIABLES
# =====================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

# =====================================================
# AWS PROVIDER
# Credentials AWS CLI profile/environment se aayengi
# =====================================================

provider "aws" {
  region = var.aws_region
}

# =====================================================
# DEFAULT VPC
# =====================================================

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# =====================================================
# AMAZON LINUX 2023 AMI
# =====================================================

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# =====================================================
# SECURITY GROUP
# HTTP port 80 public
# SSH port 22 is not required for SSM deployment
# =====================================================

resource "aws_security_group" "calculator_sg" {
  name        = "kubernetes-calculator-sg"
  description = "HTTP access for calculator website"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Calculator website HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound access for Docker and SSM"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "kubernetes-calculator-sg"
    ManagedBy = "Terraform"
  }
}

# =====================================================
# EC2 IAM ROLE
# SSM ko EC2 manage karne ki permission
# =====================================================

resource "aws_iam_role" "calculator_ssm_role" {
  name = "calculator-ec2-ssm-role"

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

  tags = {
    Name      = "calculator-ec2-ssm-role"
    ManagedBy = "Terraform"
  }
}

# AWS-managed SSM permissions
resource "aws_iam_role_policy_attachment" "calculator_ssm_policy" {
  role = aws_iam_role.calculator_ssm_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM role ko EC2 ke saath attach karne ke liye
resource "aws_iam_instance_profile" "calculator_profile" {
  name = "calculator-ec2-instance-profile"
  role = aws_iam_role.calculator_ssm_role.name
}

# =====================================================
# EC2 INSTANCE
# =====================================================

resource "aws_instance" "calculator_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.calculator_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.calculator_profile.name
  associate_public_ip_address = true

  # EC2 boot hote hi Docker aur SSM start karo
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf install -y docker
    systemctl enable --now docker

    if ! rpm -q amazon-ssm-agent >/dev/null 2>&1; then
      dnf install -y amazon-ssm-agent
    fi

    systemctl enable --now amazon-ssm-agent
  EOF

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "calculator-server"
    Environment = "development"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.calculator_ssm_policy
  ]
}

# =====================================================
# OUTPUTS
# =====================================================

output "instance_id" {
  description = "Calculator EC2 instance ID"
  value       = aws_instance.calculator_server.id
}

output "public_ip" {
  description = "Calculator EC2 public IP"
  value       = aws_instance.calculator_server.public_ip
}

output "website_url" {
  description = "Calculator website URL"
  value       = "http://${aws_instance.calculator_server.public_ip}"
}

output "security_group_id" {
  description = "Calculator Security Group ID"
  value       = aws_security_group.calculator_sg.id
}

output "iam_instance_profile" {
  description = "EC2 IAM instance profile"
  value       = aws_iam_instance_profile.calculator_profile.name
}