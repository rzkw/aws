provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy  = "terraform"
      Repository = var.github_repo
      Scope      = "account-bootstrap"
    }
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count           = var.use_existing_oidc_provider ? 0 : 1
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = var.audience_list
  thumbprint_list = [var.github_thumbprint]

  tags = {
    Name       = "GitHubActionsOIDCProvider"
    Repository = var.github_repo
  }
}

data "aws_iam_openid_connect_provider" "github_actions" {
  count = var.use_existing_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.use_existing_oidc_provider ? data.aws_iam_openid_connect_provider.github_actions[0].arn : aws_iam_openid_connect_provider.github_actions[0].arn
}
