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
