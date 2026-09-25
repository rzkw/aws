variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "rzkw_email" {
  description = "Email for the rzkw IAM Identity Center user"
  type        = string
  sensitive   = true
}