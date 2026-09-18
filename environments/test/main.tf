# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "test"
      ManagedBy   = "terraform"
      Repository  = "rzkw/aws-terraform"
    }
  }
}

# OIDC Provider Module
module "oidc_provider" {
  source = "../../modules/oidc-provider"

  use_existing_oidc_provider = var.use_existing_oidc_provider
  github_repo                = var.github_repo
  role_name                  = var.role_name
  managed_policy_arns        = var.managed_policy_arns
}
