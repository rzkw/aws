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
