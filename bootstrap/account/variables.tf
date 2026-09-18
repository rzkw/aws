variable "aws_region" {
  description = "AWS region for provider operations"
  type        = string
  default     = "us-east-1"
}

variable "github_repo" {
  description = "GitHub repository name (format: owner/repo)"
  type        = string
  default     = "rzkw/aws-terraform"
}

variable "github_thumbprint" {
  description = "GitHub OIDC thumbprint"
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "audience_list" {
  description = "List of allowed audiences for the OIDC provider"
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "use_existing_oidc_provider" {
  description = "Whether to use an existing OIDC provider instead of creating one"
  type        = bool
  default     = false
}
