variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID that owns the budgets; used to build the budget import IDs"
  type        = string
}

variable "budget_subscriber_emails" {
  description = "Email addresses to notify for budget alerts"
  type        = list(string)
  default     = []
}
