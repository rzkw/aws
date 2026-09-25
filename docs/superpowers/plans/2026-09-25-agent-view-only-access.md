# Agent View-Only Access Implementation Plan

> **For review:** This document is a proposed implementation. It does not change AWS resources by itself.

**Goal:** Give `agent-walkllc` read-only access through the existing `read-only` group and explicitly deny IAM and infrastructure creation or escalation actions.

**Approach:** Keep AWS-managed `ViewOnlyAccess` as the only allow policy. Add one small customer-managed deny policy to the same group. Do not grant CloudShell access. Keep the existing user-to-group membership.

**Important scope:** `ViewOnlyAccess` is account-wide read-only access. The requested design intentionally allows viewing current and future resources across the account, but grants no write access. AWS-managed policies cannot be limited to only resources that exist today.

## Files

- Modify: `environments/test/iam/main.tf`
- Modify: `environments/test/iam/imports.tf`
- Create: `environments/test/iam/policies/agent-view-only-deny-mutations.json`

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
        "iam:CreateLoginProfile",
        "iam:UpdateLoginProfile",
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

## Implementation Steps

1. Add the policy JSON exactly as shown above.
2. Replace the group’s `ReadOnlyAccess` attachment with `ViewOnlyAccess`.
3. Add the deny-only customer-managed policy and attach it to `read-only`.
4. Keep the existing user-group membership.
5. Confirm that no CloudShell policy is added.
6. Validate the policy with IAM Access Analyzer policy validation.
7. Review the Terraform plan for only these IAM changes:
   - Remove `ReadOnlyAccess` from `read-only`.
   - Add `ViewOnlyAccess` to `read-only`.
   - Create and attach `agent-walkllc-view-only-deny-mutations`.
   - Make no changes to `agent-walkllc`, `rzkw-iam`, `admin`, or other deployed resources.

## Security Result

`agent-walkllc` will be able to inspect AWS resources through the AWS CLI or other AWS API clients using its normal credentials. It will not receive CloudShell access.

The explicit deny blocks:

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
- Confirmed `AWSCloudShellFullAccess` is not part of the proposed configuration.
- Confirmed `ViewOnlyAccess` is an AWS-managed policy with read-only actions.
- Confirmed AWS policy evaluation gives explicit denies precedence over allows.
- Confirmed the proposed EC2, NAT gateway, EKS, IAM, access-key, and permissions-boundary actions are IAM actions documented by AWS service authorization references.
- Confirmed the repository uses Terraform AWS provider version `~> 6.0` in the IAM environment.
