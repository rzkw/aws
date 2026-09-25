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

### Module Documentation

<!-- BEGIN_TF_DOCS oidc-provider -->
# oidc-provider Module

Terraform module that provisions a GitHub Actions OIDC provider and IAM role, enabling secure keyless authentication for GitHub Actions workflows. Can reuse an existing OIDC provider when one is already configured in the account.

## Usage

```hcl
module "oidc_provider" {
  source = "../../modules/oidc-provider"

  use_existing_oidc_provider = true
  github_repo                = "<owner>/<repo>"
  role_name                  = "GitHubActionsServiceRole-Terraform"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}
```

The IAM role trusts the GitHub Actions OIDC provider with a subject claim scoped to `github_repo` (`repo:<owner>/<repo>:*`) and an audience of `sts.amazonaws.com`. See [docs/architecture.md](../../docs/architecture.md) for the trust flow.

## Security Considerations

- **Least privilege**: attach only the minimum managed or inline policies the role needs.
- **Repository scope**: the trust policy subject is scoped to the specific repository.
- **Branch control**: restrict subjects further (e.g., `repo:<owner>/<repo>:ref:refs/heads/main`) for read-after-apply workflows.
- **Session duration**: keep `max_session_duration` as short as practical.

## Requirements

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.github_actions_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_openid_connect_provider.github_actions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audience_list"></a> [audience\_list](#input\_audience\_list) | List of allowed audiences for the OIDC provider | `list(string)` | <pre>[<br/>  "sts.amazonaws.com"<br/>]</pre> | no |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | GitHub repository name in the format 'owner/repo' | `string` | n/a | yes |
| <a name="input_github_thumbprint"></a> [github\_thumbprint](#input\_github\_thumbprint) | GitHub OIDC thumbprint | `string` | `"6938fd4d98bab03faadb97b34396831e3780aea1"` | no |
| <a name="input_inline_policies"></a> [inline\_policies](#input\_inline\_policies) | Map of inline policy names to policy documents (JSON strings) | `map(string)` | `{}` | no |
| <a name="input_managed_policy_arns"></a> [managed\_policy\_arns](#input\_managed\_policy\_arns) | List of IAM managed policy ARNs to attach to the role | `list(string)` | `[]` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration in seconds (3600-43200) | `number` | `3600` | no |
| <a name="input_path"></a> [path](#input\_path) | Path for the IAM role | `string` | `"/"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the IAM role for GitHub Actions | `string` | `"GitHubActionsServiceRole-Terraform"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_use_existing_oidc_provider"></a> [use\_existing\_oidc\_provider](#input\_use\_existing\_oidc\_provider) | Whether to use an existing OIDC provider instead of creating a new one | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the GitHub Actions OIDC provider |
| <a name="output_oidc_provider_url"></a> [oidc\_provider\_url](#output\_oidc\_provider\_url) | URL of the GitHub Actions OIDC provider |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the GitHub Actions IAM role |
| <a name="output_role_id"></a> [role\_id](#output\_role\_id) | ID of the GitHub Actions IAM role |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the GitHub Actions IAM role |
| <a name="output_role_unique_id"></a> [role\_unique\_id](#output\_role\_unique\_id) | Unique ID of the GitHub Actions IAM role |
<!-- END_TF_DOCS -->
<!-- END_TF_DOCS oidc-provider -->

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