provider "aws" {
  region = var.aws_region
}


# Users


resource "aws_iam_user" "agent_walkllc" {
  name = "agent-walkllc"

  #checkov:skip=CKV_AWS_273: legacy IAM user kept until the retirement PR; access is controlled through IAM Identity Center (SSO)
}

resource "aws_iam_user" "rzkw_iam" {
  name = "rzkw-iam"

  #checkov:skip=CKV_AWS_273: legacy IAM user kept until the retirement PR; access is controlled through IAM Identity Center (SSO)
}


# Groups


resource "aws_iam_group" "admin" {
  name = "admin"
}

resource "aws_iam_group" "read_only" {
  name = "read-only"
}

resource "aws_iam_user_group_membership" "agent_walkllc_read_only" {
  user   = aws_iam_user.agent_walkllc.name
  groups = [aws_iam_group.read_only.name]
}

resource "aws_iam_user_group_membership" "rzkw_iam_admin" {
  user   = aws_iam_user.rzkw_iam.name
  groups = [aws_iam_group.admin.name]
}


# Group policy attachments for admin 
# (policies attach to groups, never to users directly)


resource "aws_iam_group_policy_attachment" "admin_administrator_access" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

  #checkov:skip=CKV_AWS_274: rzkw must operate at admin level (write access to all deployed resources and billing); the SSO TerraformAdministrator permission set mirrors this
}

resource "aws_iam_group_policy_attachment" "admin_iam_user_change_password" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}


# Group policy attachments for agent



resource "aws_iam_group_policy_attachment" "read_only_view_only_access" {
  group      = aws_iam_group.read_only.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "read_only_deny_changes" {
  group      = aws_iam_group.read_only.name
  policy_arn = aws_iam_policy.agent_view_only_deny_changes.arn
}


# Deny agent from creating infra, changing IAM


resource "aws_iam_policy" "agent_view_only_deny_changes" {
  name        = "agent-walkllc-view-only-deny-changes"
  description = "Explicitly blocks IAM and infrastructure changes for the read-only group"
  policy      = file("${path.module}/policies/agent-view-only-deny-changes.json")
}


data "aws_caller_identity" "current" {}


# Get ARNs, Identity Store IDs of SSO instances


data "aws_ssoadmin_instances" "sso_instance" {}


# Create Identity Store user rzkw for Terraform admin


resource "aws_identitystore_user" "rzkw" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso_instance.identity_store_ids)[0]

  display_name = "rzkw"
  user_name    = "rzkw"

  name {
    given_name  = "rzkw"
    family_name = "operator"
  }

  emails {
    value = var.rzkw_email
  }
}

resource "aws_ssoadmin_permission_set" "terraform_admin" {
  name             = "TerraformAdministrator"
  instance_arn     = tolist(data.aws_ssoadmin_instances.sso_instance.arns)[0]
  session_duration = "PT12H"
}

resource "aws_ssoadmin_account_assignment" "terraform_admin_rzkw" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso_instance.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.terraform_admin.arn

  principal_id   = aws_identitystore_user.rzkw.user_id
  principal_type = "USER"

  target_id   = data.aws_caller_identity.current.account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_managed_policy_attachment" "terraform_admin" {
  depends_on = [aws_ssoadmin_account_assignment.terraform_admin_rzkw]

  instance_arn       = tolist(data.aws_ssoadmin_instances.sso_instance.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.terraform_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

  #checkov:skip=CKV_AWS_274: the TerraformAdministrator permission set intentionally grants rzkw full admin access through SSO
}

resource "aws_iam_role" "agent_view_only" {
  name        = "agent-view-only"
  description = "View-only role assumed by the agent through the SSO profile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSReservedSSO_*"
          }
        }
      }
    ]
  })
}


# Role policy attachments for agent: view only, deny IAM/infra changes


resource "aws_iam_role_policy_attachment" "agent_view_only" {
  role       = aws_iam_role.agent_view_only.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "agent_view_only_deny_changes" {
  role       = aws_iam_role.agent_view_only.name
  policy_arn = aws_iam_policy.agent_view_only_deny_changes.arn
}
