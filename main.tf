terraform {
  required_version = "1.0.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.23.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}
resource "aws_security_group" "bastiao" {
    name = "bastiao"
        ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#Geração da chave SSH
resource "tls_private_key" "dev_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
#Geração da chave SSH
resource "aws_key_pair" "generated_key" {
  key_name   = var.generated_key_name
  public_key = tls_private_key.dev_key.public_key_openssh

  provisioner "local-exec" { # Generate "terraform-key-pair.pem" in current directory
    command = <<-EOT
      echo '${tls_private_key.dev_key.private_key_pem}' > ./'${var.generated_key_name}'.pem
      chmod 400 ./'${var.generated_key_name}'.pem
    EOT
  }

}

resource "aws_instance" "sebastiao" {
    ami = var.instance_ami
    instance_type = var.instance_type
    tags = {Name = "sebastiao"}
    key_name = var.generated_key_name
    vpc_security_group_ids = [aws_security_group.bastiao.id]

    ebs_block_device {
      device_name = "/dev/sda1"
      volume_size = var.size
    }
}
