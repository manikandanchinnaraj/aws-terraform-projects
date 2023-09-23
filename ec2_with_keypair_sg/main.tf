# Simple AWS EC2 instance deployment with key-pair and security group allowing ping from anywhere

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region     = "us-east-1"
}


resource "tls_private_key" "tf_generated_privkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf_generated_privkey" {
  key_name   = "general-linux-key"
  public_key = tls_private_key.tf_generated_privkey.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
    echo '${tls_private_key.tf_generated_privkey.private_key_pem}' > ./general_linux_priv_key.pem
    chmod 400 ./general_linux_priv_key.pem
    EOT
  }

}

resource "aws_security_group" "first-sg-terraform" {
  name        = "allow_ping_ssh"
  description = "Allow ICMP"

  ingress {
    description = "ICMP V4"
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All Edgress Traffic from EC2 instance"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    iac_type    = "terraform"
    deployed_by = "terraform-deployer"
  }
}


resource "aws_instance" "first-ec2-terraform" {
  ami                         = "ami-03a6eaae9938c858c"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.tf_generated_privkey.key_name
  security_groups             = [aws_security_group.first-sg-terraform.name]
  tags = {
    infra      = "stage"
    iac_type   = "terraform"
    can_delete = "yes"
  }

}
