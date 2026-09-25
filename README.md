# AWS Terraform

[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![TFLint](https://img.shields.io/badge/linting-tflint-blue.svg?style=flat)](https://github.com/terraform-linters/tflint)
[![Checkov](https://img.shields.io/badge/security-checkov-brightgreen.svg?style=flat)](https://www.checkov.io/)

Terraform code for the Walkable development environment on AWS. It sets up the test environment, supports multiple environments, and automates deployments.

- Sets up the test environment with Terraform.
- Uses GitHub Actions OIDC, so CI does not need long-lived AWS keys.
- Supports multiple environments with a clear account mapping.
- Stores Terraform state in an encrypted, versioned S3 bucket with locking; DynamoDB is not needed.
- Stops deployment when TFLint or Checkov finds a problem.

## Deployed Infrastructure

The following resources are managed here. This list was checked against live AWS state in `us-east-1`.

| Resource | Notes |
| --- | --- |
| S3 remote state bucket | Encrypted with AES256, versioned, and protected by native `.tflock` locking |
| GitHub Actions OIDC provider | Uses `token.actions.githubusercontent.com` and the audience `sts.amazonaws.com` |
| GitHub Actions IAM role | CI assumes this role through OIDC; trust conditions limit it to this repository |
| AWS Budgets | Cost budgets with email and threshold alerts |

## Estimated Monthly Cost

Costs are shown in AUD using the fixed rate **US$1.00 = A$1.55**.

Manual AWS Cost Explorer snapshot from 2026-09-18 (account-level, `us-east-1`):

- Current-month actual: **A$0.0006** (US$0.00038 × 1.55)
- Current-month forecast: **A$0.0006** (US$0.00038 × 1.55)

This is account-level data and may include AWS use outside this repository. Cost Explorer is not queried during documentation refresh because each API call costs money. The value is a manual snapshot and is refreshed as needed.

## Documentation

- [Getting Started](docs/getting-started.md) — set up credentials and deploy the environment.
- [Architecture](docs/architecture.md) — understand the bootstrap stack, environments, OIDC flow, and Terraform state.
- [Security](docs/security.md) — protect credentials, state, CI, and documentation.
- [Verification](docs/verification.md) — run checks and review the sources used.
- [Module: oidc-provider](modules/oidc-provider/README.md) — the OIDC provider and IAM role module.

## Security

- Never put credentials, tokens, private keys, AWS account IDs, ARNs, resource IDs, or state bucket names in documentation. See [Repository Guidance](AGENTS.md).
- CI uses GitHub Actions OIDC and temporary credentials instead of long-lived AWS keys.
- Terraform state stays in encrypted, versioned S3 with native locking. Every root uses an explicit state key.
- Do not commit `.tfvars`; pass values through environment variables or CLI flags.
- TFLint and Checkov run as required CI checks. If either check fails, deployment stops.

See [Security details](docs/security.md) for the full guidance.
