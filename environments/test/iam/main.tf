provider "aws" {
  region = var.aws_region
}

locals {
  iam_users = toset([
    "agent-walkllc",
    "rzkw-iam",
  ])

  iam_groups = toset([
    "admin",
    "read-only",
  ])

  group_memberships = {
    "agent-walkllc/read-only" = {
      user   = "agent-walkllc"
      groups = ["read-only"]
    }
    "rzkw-iam/admin" = {
      user   = "rzkw-iam"
      groups = ["admin"]
    }
  }

  group_policy_attachments = {
    "admin/AdministratorAccess"   = "arn:aws:iam::aws:policy/AdministratorAccess"
    "admin/SystemAdministrator"   = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
    "admin/DatabaseAdministrator" = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
    "admin/NetworkAdministrator"  = "arn:aws:iam::aws:policy/job-function/NetworkAdministrator"
    "read-only/ReadOnlyAccess"    = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }

  user_policy_attachments = {
    "rzkw-iam/IAMUserChangePassword"        = "arn:aws:iam::aws:policy/IAMUserChangePassword"
    "rzkw-iam/SignInLocalDevelopmentAccess" = "arn:aws:iam::aws:policy/SignInLocalDevelopmentAccess"
  }
}

resource "aws_iam_user" "this" {
  for_each = local.iam_users

  name = each.value
}

resource "aws_iam_group" "this" {
  for_each = local.iam_groups

  name = each.value
}

resource "aws_iam_user_group_membership" "this" {
  for_each = local.group_memberships

  user   = each.value.user
  groups = each.value.groups
}

resource "aws_iam_group_policy_attachment" "this" {
  for_each = local.group_policy_attachments

  group      = split("/", each.key)[0]
  policy_arn = each.value
}

resource "aws_iam_user_policy_attachment" "this" {
  for_each = local.user_policy_attachments

  user       = split("/", each.key)[0]
  policy_arn = each.value
}