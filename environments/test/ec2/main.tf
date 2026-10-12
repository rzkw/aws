# Code from https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-create#configuration-blocks

provider "aws" {
  region = var.aws_region
}


# Query cloud provider for info: fetch data about latest AWS image matching specified filter. Keeps config dynamic, avoids hardcoded values


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}


# Defines components of infra. Instance can be referred to by resource address: aws_instance.app_server


resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.nano"

  tags = {
    Name = "dev-machine"
  }
}


# Run terraform fmt and terraform validate to format and identify erros in config before running terraform plan and apply