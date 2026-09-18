import {
  to = aws_iam_user.this["agent-walkllc"]
  id = "agent-walkllc"
}

import {
  to = aws_iam_user.this["rzkw-iam"]
  id = "rzkw-iam"
}

import {
  to = aws_iam_group.this["admin"]
  id = "admin"
}

import {
  to = aws_iam_group.this["read-only"]
  id = "read-only"
}

import {
  to = aws_iam_user_group_membership.this["agent-walkllc/read-only"]
  id = "agent-walkllc/read-only"
}

import {
  to = aws_iam_user_group_membership.this["rzkw-iam/admin"]
  id = "rzkw-iam/admin"
}

import {
  to = aws_iam_group_policy_attachment.this["admin/AdministratorAccess"]
  id = "admin/arn:aws:iam::aws:policy/AdministratorAccess"
}

import {
  to = aws_iam_group_policy_attachment.this["admin/SystemAdministrator"]
  id = "admin/arn:aws:iam::aws:policy/job-function/SystemAdministrator"
}

import {
  to = aws_iam_group_policy_attachment.this["admin/DatabaseAdministrator"]
  id = "admin/arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}

import {
  to = aws_iam_group_policy_attachment.this["admin/NetworkAdministrator"]
  id = "admin/arn:aws:iam::aws:policy/job-function/NetworkAdministrator"
}

import {
  to = aws_iam_group_policy_attachment.this["read-only/ReadOnlyAccess"]
  id = "read-only/arn:aws:iam::aws:policy/ReadOnlyAccess"
}

import {
  to = aws_iam_user_policy_attachment.this["rzkw-iam/IAMUserChangePassword"]
  id = "rzkw-iam/arn:aws:iam::aws:policy/IAMUserChangePassword"
}

import {
  to = aws_iam_user_policy_attachment.this["rzkw-iam/SignInLocalDevelopmentAccess"]
  id = "rzkw-iam/arn:aws:iam::aws:policy/SignInLocalDevelopmentAccess"
}