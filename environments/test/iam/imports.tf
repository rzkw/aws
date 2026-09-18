import {
  to = aws_iam_user.agent_walkllc
  id = "agent-walkllc"
}

import {
  to = aws_iam_user.rzkw_iam
  id = "rzkw-iam"
}

import {
  to = aws_iam_group.admin
  id = "admin"
}

import {
  to = aws_iam_group.read_only
  id = "read-only"
}

import {
  to = aws_iam_user_group_membership.agent_walkllc_read_only
  id = "agent-walkllc/read-only"
}

import {
  to = aws_iam_user_group_membership.rzkw_iam_admin
  id = "rzkw-iam/admin"
}

import {
  to = aws_iam_group_policy_attachment.admin_administrator_access
  id = "admin/arn:aws:iam::aws:policy/AdministratorAccess"
}

import {
  to = aws_iam_group_policy_attachment.admin_system_administrator
  id = "admin/arn:aws:iam::aws:policy/job-function/SystemAdministrator"
}

import {
  to = aws_iam_group_policy_attachment.admin_database_administrator
  id = "admin/arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}

import {
  to = aws_iam_group_policy_attachment.admin_network_administrator
  id = "admin/arn:aws:iam::aws:policy/job-function/NetworkAdministrator"
}

import {
  to = aws_iam_group_policy_attachment.read_only_read_only_access
  id = "read-only/arn:aws:iam::aws:policy/ReadOnlyAccess"
}

import {
  to = aws_iam_user_policy_attachment.rzkw_iam_user_change_password
  id = "rzkw-iam/arn:aws:iam::aws:policy/IAMUserChangePassword"
}

import {
  to = aws_iam_user_policy_attachment.rzkw_iam_sign_in_local_development
  id = "rzkw-iam/arn:aws:iam::aws:policy/SignInLocalDevelopmentAccess"
}
