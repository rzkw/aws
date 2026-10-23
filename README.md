# AWS labs

[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![TFLint](https://img.shields.io/badge/linting-tflint-blue.svg?style=flat)](https://github.com/terraform-linters/tflint)
[![Checkov](https://img.shields.io/badge/security-checkov-brightgreen.svg?style=flat)](https://www.checkov.io/)

Terraform code for Walkable LLC's internal dev environment on AWS, built on a starter kit by [Towards The Cloud](https://github.com/towardsthecloud/aws-terraform-starter-kit). 

- The kit is deployed by running `make setup`, automating S3 bucket deployment for remote state backend
- Infrastructure is deployed by a GitHub Actions workflow with OIDC auth, so CI doesn't need long-lived AWS keys.
- Supports multiple environments with a clear account mapping (though a single test env is currently deployed)
- Merge gates include TFLint and Checkov, blocking deployment when code quality and vulnerability checks fail

## Why use a starter kit?

The starter kit allows building on an existing codebase, mirroring how real infra work happens - reading, understanding, and extending. 

Hand-built/agent assisted CI/CD workflows and remote state can be seen in my [web app](https://github.com/rzkw/walkable/blob/main/.github/workflows/dependabot-auto-approve.yml) and [OCI compute](https://github.com/rzkw/oci-cloudinfra/pull/85) repos.

## Deployed Infrastructure

The following resources are managed here. This list was checked against live AWS state in `us-east-1`.

| Resource | Notes |
| --- | --- |
| S3 remote state bucket | Encrypted with AES256, versioned, and protected by native `.tflock` locking |
| GitHub Actions OIDC provider | Uses `token.actions.githubusercontent.com` and the audience `sts.amazonaws.com` |
| GitHub Actions IAM role | CI assumes this role through OIDC |
| AWS Budgets | Cost budgets with email and threshold alerts |

## Estimated Monthly Cost

Costs are shown in AUD using the fixed rate **US$1.00 = A$1.55**.

Manual AWS Cost Explorer snapshot from 2026-09-18 (account-level, `us-east-1`):

- Current-month actual: **A$0.0006** (US$0.00038 × 1.55)
- Current-month forecast: **A$0.0006** (US$0.00038 × 1.55)

This is account-level data and may include AWS use outside this repository. Cost Explorer is not queried because each API call costs money. The value is a manual snapshot, refreshed as needed.

## Documentation

- [Getting Started](docs/getting-started.md) — set up credentials and deploy the environment.
- [Architecture](docs/architecture.md) — understand the bootstrap stack, environments, OIDC flow, and Terraform state.
- [Security](docs/security.md) — protect credentials, state, CI, and documentation.
- [Verification](docs/verification.md) — run checks and review the sources used.
- [Module: oidc-provider](modules/oidc-provider/README.md) — the OIDC provider and IAM role module.

## Security

- Never put credentials, tokens, private keys, AWS account IDs, ARNs, resource IDs, or state bucket names in documentation. See [Repository Guidance](AGENTS.md).
- Do not commit `.tfvars`; pass values through environment variables or CLI flags.

See [Security details](docs/security.md) for the full guidance.
