# Resolving Checkov findings that blocked PR #15

**Date:** 2026-10-19 · **PR:** #15 (IAM Identity Center access: one human operator, one automation account) · **Outcome:** 14 findings resolved; local scan green

## The problem

Checkov failed 13 checks on PR #15 and stopped the pipeline. A newer local Checkov found a 14th. The findings split into fixes and accepted risks.

**Fixed in code.** The EC2 instance now requires IMDSv2 for instance metadata. The instance has an IAM instance profile role. A password policy moved from a user to the admin group, and a redundant sign-in policy was removed. The VPC's default security group no longer allows traffic. SSH ingress is a variable whose value Terraform itself rejects when it is `0.0.0.0/0`, because a scan cannot see through a variable.

**Skipped with justification.** EBS encryption and EBS optimization (a disposable test instance with no sensitive data; the burstable instance has no optimization setting), detailed monitoring (a paid service, so basic monitoring is kept), VPC flow logs (billed; S3 delivery would cost a few cents a month), two legacy IAM users awaiting a retirement PR, and four admin-by-design roles, because the operator needs full access to all deployed resources and billing.

## Bugs found while verifying

The fixes exposed three problems the pipeline had never reached, because Checkov failed first:

1. `vpc/main.tf` referenced a VPC resource that does not exist, so `terraform validate` failed for that root.
2. `iam/imports.tf` kept five import blocks for resources already removed from the configuration.
3. An IAM policy file had been renamed in the configuration but not on disk.

## The surprising part

With the code green, CI still failed — and it had been failing for the wrong reason all along. Both reusable scan workflows used a bare `actions/checkout` under `pull_request_target`, which checks out the **base branch**. CI was scanning `main`, not the pull request. A two-line fix pins the checkout to the pull request head; it must land on `main` before this PR's check can pass.

## Verification

`terraform fmt -check -recursive`, `tflint --recursive`, and `init -backend=false` plus `validate` passed for all four changed roots. Checkov reported 54 passed, 0 failed, 11 skipped. Commits are signed.

## Lesson

A security scan that passes because it looks at the wrong branch is worse than one that fails outright. Check what CI actually checks out before trusting a green check — or chasing a red one.

## References

- [Plan: human and bot identity access](../docs/plans/2026-09-26-human-bot-identity-access.md) — includes the Checkov amendment
- Commits in PR #15: `0a145b0`, `3d1a0ff`, `778c680`, `37aa696`, `9dc4d59`, `848b9b0`, `397fa1b`
- [Terraform custom validation rules](https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules) — Terraform documentation
- [Checkov policy index](https://www.checkov.io/5.Policy%20Index/terraform.html) — Checkov documentation
- [Instance metadata service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html) — AWS documentation
