# Human and Bot Identity Access Implementation Plan

> **For review:** This document is a proposed implementation. It does not change AWS resources by itself. It includes the Terraform code drafted for the implementation PR.

**Goal:** Give the human operator (rzkw) AWS access through IAM Identity Center with no long-lived keys, and give the OpenCode harness a view-only IAM role it can assume with temporary credentials.

**Approach:** Bootstrap a single-account AWS organization and the IAM Identity Center organization instance once in the console. Terraform then manages the Identity Center user, the `TerraformAdministrator` permission set, the account assignment, and a new `agent-view-only` IAM role. The harness assumes the role from the operator's SSO profile, so it never holds access keys.

**Scope decisions (kept small on purpose):**
- The organization and Identity Center instance are a one-time console bootstrap. The AWS provider exposes the instance only as a data source, so there is nothing to manage for it in Terraform. (edit 12/10 @rzkw: done)
- No inline `sts:AssumeRole` policy is added: `AdministratorAccess` already allows it.
- The agent role trust uses a wildcard on `AWSReservedSSO_*` roles instead of pinning the unknown SSO role ARN hash.
- The existing `agent-view-only-deny-changes` policy is reused and attached to the role; no new policy files.
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

data "aws_ssoadmin_instances" "sso_instance" {}

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

resource "aws_iam_role_policy_attachment" "agent_view_only_deny_changes" {
  role       = aws_iam_role.agent_view_only.name
  policy_arn = aws_iam_policy.agent_view_only_deny_changes.arn
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
8. Later, after verification, retire the `agent-walkllc` IAM user, `read-only` group, and memberships in a separate PR. The deny-changes policy stays and is reused by the role.

## Security Result

The human logs in once per session and Terraform uses temporary credentials. The harness has no IAM user, no password, and no access keys. It can only view resources through `ViewOnlyAccess` plus the existing deny-changes policy. GitHub collaborator access for `agent-walkllc` is unchanged.

## Checkov Scan Amendment (added 2026-10-17)

The Checkov CI scan for this PR failed 13 checks (14 with a newer local Checkov). All are resolved in code; the local scan now exits 0 with 0 failed and 11 skipped checks. The CI Checkov job itself still fails because it checks out the base branch instead of the PR head (a workflow defect found during review); that fix must land on `main` first, so the CI check only turns green after a re-run.

**Fixed in code:**

- CKV_AWS_79: the dev machine now enforces IMDSv2 (`http_tokens = "required"`).
- CKV2_AWS_41: an instance profile role (`dev-machine-role`) is attached to the instance.
- CKV_AWS_40 (both): `IAMUserChangePassword` moved from the user to the `admin` group. `SignInLocalDevelopmentAccess` was removed after checking the docs: it only powers `aws login` with console credentials, and with SSO configured the operator uses `aws sso login`.
- CKV2_AWS_12: `aws_default_security_group` with no rules takes over the VPC default security group. (Note: this check is about the default security group, not routing.)
- Also found and fixed while verifying: `aws_vpc.this` references in `vpc/main.tf` (the resource is `vpc-1`), the policy file name that the config referenced but did not exist, and 5 stale `import` blocks whose resources are no longer in configuration.

**Skipped with justification:**

- CKV_AWS_8: the root volume holds no sensitive data; this disposable test box skips volume encryption by operator decision. (Enabling it for real is one `root_block_device` block away if wanted later.)
- CKV_AWS_135: this burstable test instance has no dedicated EBS throughput requirement; EBS optimization does not apply to it.
- CKV_AWS_126: detailed monitoring is a paid service (charged per metric per hour); basic monitoring is kept for this test deployment.
- CKV_AWS_382: the test instance needs unrestricted outbound traffic for package installs and updates.
- CKV2_AWS_11: VPC flow logs are billed (CloudWatch ingestion or S3 vended-log charges). Cheapest option would be S3 delivery (storage only, a few cents per month on an idle test VPC); skipped for now.
- CKV_AWS_273 (both users): legacy IAM users `agent-walkllc` and `rzkw-iam` are kept for now; SSO is the primary access path. Step 8 retires `agent-walkllc` and the `read-only` group; the fate of `rzkw-iam` is decided separately. Skipped for now and may be addressed later.
- CKV_AWS_274 (four): the `admin` group, the SSO `TerraformAdministrator` permission set, the CI deploy role, and the EC2 `dev-machine-role` intentionally carry `AdministratorAccess`; rzkw requires full admin (write access to all deployed resources and all billing), and the CI deploy role and the test instance need broad permissions to work as designed.

**Apply note:** the `ec2/` root now needs `TF_VAR_ssh_public_key` (public key of the operator key pair) and `TF_VAR_ssh_ingress_cidr` (operator IP). The instance is replaced on the next apply because the key pair is added.

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
- [EC2: require IMDSv2 (instance metadata service version 2)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)
- [EC2: basic monitoring is free, detailed monitoring is charged per metric](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/manage-detailed-monitoring.html)
- [Amazon VPC FAQ: VPC flow log ingestion and archival charges apply](https://aws.amazon.com/vpc/faqs/)
- [AWS managed policy `SignInLocalDevelopmentAccess`: programmatic access with console credentials](https://docs.aws.amazon.com/signin/latest/userguide/security-iam-awsmanpol.html)
- [VPC: the default security group should restrict all traffic](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
