# Agent View-Only Access Implementation Plan

> **For review:** This document is a proposed implementation. It does not change AWS resources by itself.

**Goal:** Give `agent-walkllc` read-only access through the existing `read-only` group. Explicitly deny IAM and infrastructure creation or escalation actions, and deny AWS Management Console access.

**Approach:** Keep AWS-managed `ViewOnlyAccess` as the only allow policy. Add one small customer-managed deny policy to the same group. Deny console access by removing the console password (login profile) and blocking its recreation. Do not grant CloudShell access. Keep the existing user-to-group membership.

**Important scope:** `ViewOnlyAccess` is account-wide read-only access. The requested design intentionally allows viewing current and future resources across the account, but grants no write access. AWS-managed policies cannot be limited to only resources that exist today.

## Files

- Modify: `environments/test/iam/main.tf`
- Modify: `environments/test/iam/imports.tf`
- Create: `environments/test/iam/policies/agent-view-only-deny-mutations.json`
- Out of band (account owner, not managed by Terraform): remove the `agent-walkllc` console password; create and distribute CLI access keys.

## Policy Draft

Create `environments/test/iam/policies/agent-view-only-deny-mutations.json` with this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyIamUserAndCredentialChanges",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser",
        "iam:UpdateUser",
        "iam:DeleteUser",
        "iam:DeleteLoginProfile",
        "iam:CreateAccessKey",
        "iam:UpdateAccessKey",
        "iam:DeleteAccessKey",
        "iam:CreateServiceSpecificCredential",
        "iam:UpdateServiceSpecificCredential",
        "iam:DeleteServiceSpecificCredential",
        "iam:UploadSSHPublicKey",
        "iam:UpdateSSHPublicKey",
        "iam:DeleteSSHPublicKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyConsoleAccess",
      "Effect": "Deny",
      "Action": [
        "iam:CreateLoginProfile",
        "iam:UpdateLoginProfile",
        "iam:ChangePassword"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyIamPolicyChanges",
      "Effect": "Deny",
      "Action": [
        "iam:CreatePolicy",
        "iam:CreatePolicyVersion",
        "iam:SetDefaultPolicyVersion",
        "iam:DeletePolicy",
        "iam:DeletePolicyVersion",
        "iam:PutUserPolicy",
        "iam:DeleteUserPolicy",
        "iam:AttachUserPolicy",
        "iam:DetachUserPolicy",
        "iam:PutGroupPolicy",
        "iam:DeleteGroupPolicy",
        "iam:AttachGroupPolicy",
        "iam:DetachGroupPolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyIamRoleAndGroupChanges",
      "Effect": "Deny",
      "Action": [
        "iam:CreateRole",
        "iam:UpdateRole",
        "iam:UpdateRoleDescription",
        "iam:UpdateAssumeRolePolicy",
        "iam:DeleteRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:CreateGroup",
        "iam:UpdateGroup",
        "iam:DeleteGroup",
        "iam:CreateServiceLinkedRole",
        "iam:DeleteServiceLinkedRole",
        "iam:PutRolePermissionsBoundary",
        "iam:DeleteRolePermissionsBoundary",
        "iam:PutUserPermissionsBoundary",
        "iam:DeleteUserPermissionsBoundary"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyRoleEscalation",
      "Effect": "Deny",
      "Action": [
        "iam:PassRole",
        "sts:AssumeRole",
        "sts:AssumeRoleWithSAML",
        "sts:AssumeRoleWithWebIdentity"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyEc2InstanceCreation",
      "Effect": "Deny",
      "Action": [
        "ec2:RunInstances",
        "ec2:RunScheduledInstances",
        "ec2:RequestSpotInstances",
        "ec2:CreateFleet",
        "ec2:RequestSpotFleet"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyNatGatewayCreation",
      "Effect": "Deny",
      "Action": "ec2:CreateNatGateway",
      "Resource": "*"
    },
    {
      "Sid": "DenyEksClusterCreation",
      "Effect": "Deny",
      "Action": "eks:CreateCluster",
      "Resource": "*"
    }
  ]
}
```

The policy is deny-only. It does not grant access. The AWS-managed `ViewOnlyAccess` policy remains the only allow policy for resource inspection.

## Terraform Changes

In `environments/test/iam/main.tf`:

1. Replace the existing `ReadOnlyAccess` group attachment with:

```hcl
resource "aws_iam_group_policy_attachment" "read_only_view_only_access" {
  group      = aws_iam_group.read_only.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}
```

2. Add the customer-managed deny policy:

```hcl
resource "aws_iam_policy" "agent_view_only_deny_mutations" {
  name        = "agent-walkllc-view-only-deny-mutations"
  description = "Explicitly blocks IAM and infrastructure changes for the read-only group"
  policy      = file("${path.module}/policies/agent-view-only-deny-mutations.json")
}

resource "aws_iam_group_policy_attachment" "read_only_deny_mutations" {
  group      = aws_iam_group.read_only.name
  policy_arn = aws_iam_policy.agent_view_only_deny_mutations.arn
}
```

3. Leave `aws_iam_user_group_membership.agent_walkllc_read_only` unchanged.

4. Do not add `AWSCloudShellFullAccess` or any direct policy attachment to `agent-walkllc`.

In `environments/test/iam/imports.tf`:

1. Replace the old `ReadOnlyAccess` attachment import with the `ViewOnlyAccess` attachment address and policy ID after the live attachment is created during the controlled Terraform transition.
2. Add an import block for the customer-managed policy only if the policy is created outside Terraform before adoption.
3. Add an import block for the deny-policy group attachment only if it is attached outside Terraform before adoption.

The existing attachment address is already in state from the previous import. The implementation must preserve that state during the policy replacement; it must not orphan or recreate the `read-only` group.

### Console and CLI credentials

- The `agent-walkllc` console password (login profile) is not managed in Terraform. The account owner removes it out of band with `aws iam delete-login-profile`. Recreating it is blocked by the `DenyConsoleAccess` policy statement.
- CLI access keys for `agent-walkllc` are created and distributed out of band by the account owner. They are not imported into Terraform, so credentials stay out of Terraform state.

## Implementation Steps

1. The account owner removes the console password: `aws iam delete-login-profile --user-name agent-walkllc`.
2. Verify the login profile no longer exists: `aws iam get-login-profile --user-name agent-walkllc` returns `NoSuchEntity`.
3. Add the policy JSON exactly as shown above.
4. Replace the group’s `ReadOnlyAccess` attachment with `ViewOnlyAccess`.
5. Add the deny-only customer-managed policy and attach it to `read-only`.
6. Keep the existing user-group membership.
7. Confirm that no CloudShell policy is added.
8. Validate the policy with IAM Access Analyzer policy validation.
9. Review the Terraform plan for only these IAM changes:
   - Remove `ReadOnlyAccess` from `read-only`.
   - Add `ViewOnlyAccess` to `read-only`.
   - Create and attach `agent-walkllc-view-only-deny-mutations`.
   - Make no changes to `agent-walkllc`, `rzkw-iam`, `admin`, or other deployed resources.

## Security Result

`agent-walkllc` will be able to inspect AWS resources through the AWS CLI or other AWS API clients using its access keys. It will not receive CloudShell access.

AWS Management Console access is denied: the user has no console password (removed out of band) and cannot create or update login credentials or change a password (`iam:CreateLoginProfile`, `iam:UpdateLoginProfile`, `iam:ChangePassword`).

The explicit deny blocks:

- AWS Management Console access (login profile removal and blocked recreation).
- IAM users, groups, roles, and service-linked-role changes.
- IAM policy creation, deletion, version changes, attachment, and inline-policy changes.
- Access-key, login-profile, service-specific-credential, and SSH-key changes.
- Permissions-boundary changes.
- Role passing and role assumption.
- EC2 instance launch APIs.
- NAT gateway creation.
- EKS cluster creation.

Because the deny is attached to the group, it applies to `agent-walkllc` through group membership. It also protects against an accidental future allow policy attached to that group.

## References

- [Control IAM user access to the AWS Management Console](https://docs.aws.amazon.com/IAM/latest/UserGuide/console_controlling-access.html)
- [AWS CLI `delete-login-profile`](https://docs.aws.amazon.com/cli/latest/reference/iam/delete-login-profile.html)
- [ViewOnlyAccess AWS-managed policy](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/ViewOnlyAccess.html)
- [AWS managed policies for job functions](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_job-functions.html)
- [IAM policy evaluation logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)
- [IAM security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [IAM policy `Effect`](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_effect.html)
- [Amazon EC2 service authorization reference](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonec2.html)
- [Amazon EKS service authorization reference](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonelastickubernetesservice.html)
- [Terraform `aws_iam_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
- [Terraform `aws_iam_group_policy_attachment`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy_attachment)
- [Terraform `aws_iam_policy_document`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)

## Verification Performed For This Draft

- Confirmed `agent-walkllc` is already a member of `read-only`.
- Confirmed the current group attachment is `ReadOnlyAccess`.
- Confirmed `agent-walkllc` currently has a console password (login profile) and no access keys; the verification calls in this draft run as `rzkw-iam`.
- Confirmed `AWSCloudShellFullAccess` is not part of the proposed configuration.
- Confirmed `ViewOnlyAccess` is an AWS-managed policy with read-only actions.
- Confirmed AWS policy evaluation gives explicit denies precedence over allows.
- Confirmed the proposed EC2, NAT gateway, EKS, IAM, access-key, login-profile, and permissions-boundary actions are IAM actions documented by AWS service authorization references.
- Confirmed the updated policy JSON validates with IAM Access Analyzer and returns no findings.
- Confirmed the repository uses Terraform AWS provider version `~> 6.0` in the IAM environment.
