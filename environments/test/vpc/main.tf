provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "vpc-1" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "dev" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.subnet_cidr
}

resource "aws_route_table" "rt-1" {
  vpc_id = aws_vpc.this.id
}
