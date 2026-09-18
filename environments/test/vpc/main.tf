provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "this" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.subnet_cidr
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id
}