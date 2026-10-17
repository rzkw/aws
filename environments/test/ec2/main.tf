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


# SSH access: key pair created from the public key passed at apply time (TF_VAR_ssh_public_key)


resource "aws_key_pair" "dev-machine" {
  key_name   = "dev-machine-key"
  public_key = var.ssh_public_key
}


resource "aws_security_group" "dev-machine" {
  name        = "dev-machine-ssh"
  description = "SSH to dev-machine from the operator IP"

  #checkov:skip=CKV_AWS_382: test instance needs unrestricted outbound traffic for package installs and updates

  ingress {
    description = "SSH from operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Instance profile role: admin rights so the operator can test AWS API access from the box


resource "aws_iam_role" "dev-machine" {
  name = "dev-machine-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "dev-machine" {
  role       = aws_iam_role.dev-machine.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

  #checkov:skip=CKV_AWS_274: single-operator test instance needs admin rights to test AWS API access from the box
}


resource "aws_iam_instance_profile" "dev-machine" {
  name = "dev-machine-profile"
  role = aws_iam_role.dev-machine.name
}


# Defines components of infra. Instance can be referred to by resource address: aws_instance.dev-machine


resource "aws_instance" "dev-machine" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.nano"
  key_name               = aws_key_pair.dev-machine.key_name
  vpc_security_group_ids = [aws_security_group.dev-machine.id]
  iam_instance_profile   = aws_iam_instance_profile.dev-machine.name

  # Enforce IMDSv2 (latest instance metadata service version)
  metadata_options {
    http_tokens = "required"
  }

  #checkov:skip=CKV_AWS_8: no EBS volumes attached to this instance; there is no data to encrypt
  #checkov:skip=CKV_AWS_135: no EBS volumes attached; EBS optimization is not applicable to this setup
  #checkov:skip=CKV_AWS_126: detailed monitoring is a paid service; basic monitoring is kept for this test deployment

  tags = {
    Name = "dev-machine"
  }
}


# Run terraform fmt and terraform validate to format and identify erros in config before running terraform plan and apply
