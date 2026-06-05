terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "eu-west-2"
}

variable "allowed_ssh_cidr" {
  description = "Public IP address allowed to SSH into the EC2 instance, written as a CIDR block."
  type        = string
}

variable "key_name" {
  description = "Name of the existing AWS EC2 key pair used for SSH access."
  type        = string
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "infra_monitor_sg" {
  name        = "infra-monitor-sg"
  description = "Security group for the infra-monitor EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name    = "infra-monitor-sg"
    Project = "infra-monitor"
    Phase   = "may-terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.infra_monitor_sg.id

  description = "Allow SSH from my public IP"
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = var.allowed_ssh_cidr
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.infra_monitor_sg.id

  description = "Allow all outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_instance" "infra_monitor" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023_ami.value
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.infra_monitor_sg.id]
  associate_public_ip_address = true

  tags = {
    Name    = "infra-monitor-ec2"
    Project = "infra-monitor"
    Phase   = "may-terraform"
  }
}
