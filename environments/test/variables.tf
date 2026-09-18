variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "use_existing_oidc_provider" {
  description = "Whether to use an existing OIDC provider or create a new one"
  type        = bool
  default     = true
}

variable "github_repo" {
  description = "GitHub repository name (format: owner/repo)"
  type        = string
  default     = "rzkw/aws-terraform"
}

variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
  default     = "GitHubActionsServiceRole-Terraform"
}

variable "managed_policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}
