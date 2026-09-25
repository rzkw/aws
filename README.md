# AWS Terraform

[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![TFLint](https://img.shields.io/badge/linting-tflint-blue.svg?style=flat)](https://github.com/terraform-linters/tflint)
[![Checkov](https://img.shields.io/badge/security-checkov-brightgreen.svg?style=flat)](https://www.checkov.io/)

Terraform-managed infrastructure for the Walkable development environment on AWS.

- Secure GitHub Actions OIDC authentication for CI/CD deployments
- Multi-environment layout with explicit environment-to-account mapping
- Remote state on S3 with native state locking (no DynamoDB required)
- TFLint and Checkov run fail-closed in the pipeline

Sensitive values are intentionally omitted from this documentation. AWS account IDs, ARNs, resource IDs, and the state bucket name are redacted; see [Repository Guidance (AGENTS.md)](AGENTS.md) for the redaction policy.

## Deployed Infrastructure

Resources managed by this repository, confirmed against live AWS state (`us-east-1`):

| Resource | Notes |
| --- | --- |
| S3 remote state bucket | Server-side encryption (AES256), bucket versioning enabled, native `.tflock` state locking |
| GitHub Actions OIDC provider | `token.actions.githubusercontent.com`, audience `sts.amazonaws.com` |
| GitHub Actions IAM role | OIDC-federated role assumed by CI; scoped to this repository via trust conditions |
| AWS Budgets | Cost budgets with email- and threshold-based alert rules |

## Estimated Monthly Cost

Estimated monthly cost is reported in **AUD** using a fixed documented conversion rate of **US$1.00 = A$1.55**.

Snapshot taken from AWS Cost Explorer on 2026-09-18 (account-level, region `us-east-1`):

- Current-month actual spend: **A$0.0006** (US$0.00038 × 1.55)
- Current-month forecast: **A$0.0006** (US$0.00038 × 1.55)

> This is account-level Cost Explorer data and may include AWS usage unrelated to this repository. Cost Explorer is **not** queried during documentation refresh — each Cost Explorer API call incurs a fee — so this value is a manual snapshot and is refreshed on an as-needed basis.

## Repo Layout

| Path | Description |
| --- | --- |
| `bootstrap/account/` | Account bootstrap stack: OIDC provider for GitHub Actions (shared, reuses existing provider when present) |
| `environments/test/` | Test environment root: IAM role consuming bootstrap OIDC, plus VPC/IAM/budgets sub-roots |
| `modules/oidc-provider/` | Reusable OIDC provider + IAM role module |
| `docs/` | Getting-started, architecture, and verification guidance |
| `config/` | Explicit environment-to-account mapping (`environments.json`) |
| `scripts/` | Setup and cleanup helper scripts |
| `.github/workflows/` | CI/CD and documentation workflows |

## Remote State

State is stored in an S3 bucket in `us-east-1` with server-side encryption and native S3 lockfile locking. Each root module uses a distinct state key:

| Root | State key |
| --- | --- |
| `bootstrap/account` | `bootstrap/account/terraform.tfstate` |
| `environments/test` | `environments/test/terraform.tfstate` |

A missing backend key defaults to `terraform.tfstate` and silently collides with other modules — every root module must set an explicit `key` in its `backend "s3"` block.

## Quick Start

Prerequisites:

- AWS account with credentials for the target account
- GitHub repository with admin access
- Tools installed via `make install-tools` (Terraform, AWS CLI, jq, TFLint, Checkov)

Verify identity, then bootstrap:

```bash
aws sts get-caller-identity
make setup
```

Or apply a single environment root manually:

```bash
terraform -chdir=bootstrap/account init
terraform -chdir=bootstrap/account apply
terraform -chdir=environments/test init
terraform -chdir=environments/test apply
```

No `.tfvars` are committed. Set variables via environment or CLI flags. See [docs/getting-started.md](docs/getting-started.md) for the full setup.

## Documentation

- [Getting Started](docs/getting-started.md) — credentials, backend setup, and deployment workflow
- [Architecture](docs/architecture.md) — bootstrap stack, environments, OIDC trust flow, remote state
- [Verification](docs/verification.md) — validation commands, tool sources, and assumptions
- [Module: oidc-provider](modules/oidc-provider/README.md) — OIDC provider + IAM role module

## Security Considerations

- **Least privilege**: attach only the minimum managed or inline policies the role needs.
- **Repository scope**: the trust policy subject is scoped to the specific repository.
- **Branch control**: restrict subjects further (e.g., `repo:<owner>/<repo>:ref:refs/heads/main`) for read-after-apply workflows.
- **Session duration**: keep `max_session_duration` as short as practical.

## Verification

Module and repository documentation were verified using:

- **Terraform Registry** — `hashicorp/aws` provider resource and data-source types confirmed
- **AWS Knowledge MCP** — deployed infrastructure facts validated at `https://knowledge-mcp.global.api.aws`
- **Terraform Best Practices MCP** — README structure, naming, and backend conventions validated at `https://www.terraform-best-practices.com/~gitbook/mcp`
- **Terraform** — `terraform fmt -check -recursive`, `terraform validate` for all roots
- **TFLint** — recursive scan clean
- **Checkov** — security scan, fail-closed for deployments
- **AWS CLI** — read-only confirmation of live IAM, S3, budgets, and OIDC state (identifiers redacted)

See [docs/verification.md](docs/verification.md) for the exact commands and tool versions used.
