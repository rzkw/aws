# Human and Bot Identity Access Implementation Plan

> **For review:** This document is a proposed implementation. It does not change AWS resources by itself. It includes the Terraform code drafted for the implementation PR.

**Goal:** Give the human operator (rzkw) AWS access through IAM Identity Center with no long-lived keys, and give the OpenCode harness a view-only IAM role it can assume with temporary credentials.

**Approach:** Bootstrap a single-account AWS organization and the IAM Identity Center organization instance once in the console. Terraform then manages the Identity Center user, the `TerraformAdministrator` permission set, the account assignment, and a new `agent-view-only` IAM role. The harness assumes the role from the operator's SSO profile, so it never holds access keys.

**Scope decisions (kept small on purpose):**
- The organization and Identity Center instance are a one-time console bootstrap. The AWS provider exposes the instance only as a data source, so there is nothing to manage for it in Terraform.
- No inline `sts:AssumeRole` policy is added: `AdministratorAccess` already allows it.
- The agent role trust uses a wildcard on `AWSReservedSSO_*` roles instead of pinning the unknown SSO role ARN hash.
- The existing `agent-view-only-deny-mutations` policy is reused and attached to the role; no new policy files.
- All new resources go into the existing `environments/test/iam/main.tf`.
- Agent IAM user retirement happens after verification, in a later PR.

## Files

- Modify: `environments/test/iam/main.tf`
- Modify: `environments/test/iam/variables.tf`
- Out of band (account owner, once): create the organization and enable Identity Center via the console.

## Terraform Changes

In `environments/test/iam/main.tf`, add:

```hcl
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
```

In `environments/test/iam/variables.tf`, add a sensitive variable so the real email is never committed:

```hcl
variable "rzkw_email" {
  description = "Email for the rzkw IAM Identity Center user"
  type        = string
  sensitive   = true
}
```

## Implementation Steps

1. Console bootstrap (account owner, once): create the organization, then enable IAM Identity Center (organization instance). Confirm AWS Organizations is available at no charge.
2. Apply the Terraform above with the real email passed as `TF_VAR_rzkw_email`.
3. In Identity Center, the rzkw user receives an email to set a password, then registers an authenticator (MFA).
4. Run `aws configure sso` with the start URL and the `TerraformAdministrator` permission set. Name the profile `aws-admin`.
5. Add a chained profile for the harness in `~/.aws/config`:

```ini
[profile agent-view-only]
source_profile = aws-admin
role_arn = arn:aws:iam::<account-id>:role/agent-view-only
```

6. Set `AWS_PROFILE=agent-view-only` for the OpenCode harness environment.
7. Verify identity scope: `aws sts get-caller-identity` under `aws-admin` shows the SSO user; under `agent-view-only` it shows the role and `ViewOnlyAccess` permits.
8. Later, after verification, retire the `agent-walkllc` IAM user, `read-only` group, and memberships in a separate PR. The deny-mutations policy stays and is reused by the role.

## Security Result

The human logs in once per session and Terraform uses temporary credentials. The harness has no IAM user, no password, and no access keys. It can only view resources through `ViewOnlyAccess` plus the existing deny-mutations policy. GitHub collaborator access for `agent-walkllc` is unchanged.

## References

- [IAM Security Best Practices: use temporary credentials instead of long-term access keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Well-Architected SEC02-BP02: use temporary credentials](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec_identities_unique.html)
- [IAM Identity Center is the recommended service for workforce access](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture-identity-management/workforce-identity-management.html)
- [IAM roles for workloads inside AWS: temporary credentials, no long-term keys](https://aws.amazon.com/iam/features/manage-roles/)
- [IAM Roles Anywhere: roles for workloads outside AWS without long-term keys](https://aws.amazon.com/blogs/security/extend-aws-iam-roles-to-workloads-outside-of-aws-with-iam-roles-anywhere/)
- [Grant least privilege in IAM](https://repost.aws/knowledge-center/grant-least-privilege-permissions-iam)
- [AWS Organizations: available at no additional charge](https://docs.aws.amazon.com/organizations/latest/userguide/pricing.html)
- [IAM Identity Center account instances do not provide AWS CLI account access; use the organization instance](https://docs.aws.amazon.com/singlesignon/latest/userguide/account-instances-identity-center.html)
- [AWS CLI: configure SSO profile](https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html)
- [Terraform `aws_ssoadmin_permission_set`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set)
- [Terraform `aws_ssoadmin_account_assignment`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment)
- [Terraform `aws_identitystore_user`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_user)
- [Terraform `aws_iam_role`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)