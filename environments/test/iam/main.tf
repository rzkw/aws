provider "aws" {
  region = var.aws_region
}

resource "aws_iam_user" "agent_walkllc" {
  name = "agent-walkllc"
}

resource "aws_iam_user" "rzkw_iam" {
  name = "rzkw-iam"
}

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

resource "aws_iam_group_policy_attachment" "admin_administrator_access" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "admin_system_administrator" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
}

resource "aws_iam_group_policy_attachment" "admin_database_administrator" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}

resource "aws_iam_group_policy_attachment" "admin_network_administrator" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/NetworkAdministrator"
}

resource "aws_iam_group_policy_attachment" "read_only_view_only_access" {
  group      = aws_iam_group.read_only.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_policy" "agent_view_only_deny_mutations" {
  name        = "agent-walkllc-view-only-deny-mutations"
  description = "Explicitly blocks IAM and infrastructure changes for the read-only group"
  policy      = file("${path.module}/policies/agent-view-only-deny-mutations.json")
}

resource "aws_iam_group_policy_attachment" "read_only_deny_mutations" {
  group      = aws_iam_group.read_only.name
  policy_arn = aws_iam_policy.agent_view_only_deny_mutations.arn
}

resource "aws_iam_user_policy_attachment" "rzkw_iam_user_change_password" {
  user       = aws_iam_user.rzkw_iam.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_user_policy_attachment" "rzkw_iam_sign_in_local_development" {
  user       = aws_iam_user.rzkw_iam.name
  policy_arn = "arn:aws:iam::aws:policy/SignInLocalDevelopmentAccess"
}

data "aws_caller_identity" "current" {}

data "aws_ssoadmin_instances" "this" {}

resource "aws_identitystore_user" "rzkw" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

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
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  session_duration = "PT12H"
}

resource "aws_ssoadmin_account_assignment" "terraform_admin_rzkw" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.terraform_admin.arn

  principal_id   = aws_identitystore_user.rzkw.user_id
  principal_type = "USER"

  target_id   = data.aws_caller_identity.current.account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_managed_policy_attachment" "terraform_admin" {
  depends_on = [aws_ssoadmin_account_assignment.terraform_admin_rzkw]

  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.terraform_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "agent_view_only" {
  name        = "agent-view-only"
  description = "View-only role assumed by the OpenCode harness through the SSO profile"

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

resource "aws_iam_role_policy_attachment" "agent_view_only" {
  role       = aws_iam_role.agent_view_only.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "agent_view_only_deny_mutations" {
  role       = aws_iam_role.agent_view_only.name
  policy_arn = aws_iam_policy.agent_view_only_deny_mutations.arn
}
