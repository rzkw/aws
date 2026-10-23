provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "vpc-1" {
  cidr_block = var.vpc_cidr

  #checkov:skip=CKV2_AWS_11: VPC flow logs are billed (CloudWatch ingestion or S3 vended-log charges); skipped for this test deployment and noted in the PR amendment
}

# Take ownership of the VPC default security group and remove its rules,
# so the default security group restricts all traffic (CKV2_AWS_12)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc-1.id
}

resource "aws_subnet" "dev" {
  vpc_id     = aws_vpc.vpc-1.id
  cidr_block = var.subnet_cidr
}

resource "aws_route_table" "rt-1" {
  vpc_id = aws_vpc.vpc-1.id
}
