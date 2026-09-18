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
  description = "Email addresses to notify for budget alerts. The live budgets currently have no subscribers, so this is empty by default; set TF_VAR_budget_subscriber_emails before apply if notifications should manage subscribers. The AWS provider requires at least one subscriber before it can update a notification."
  type        = list(string)
  default     = []
}