variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block of the existing VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block of the existing subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "vpc_id" {
  description = "VPC ID of the existing VPC to import"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID of the existing subnet to import"
  type        = string
}

variable "route_table_id" {
  description = "Route table ID of the existing VPC main route table to import"
  type        = string
}