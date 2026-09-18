# AWS Documentation Refresh Design

## Goal

Replace the starter-kit README with accurate documentation for the deployed AWS infrastructure, add focused repository documentation, and keep module documentation current through the existing Terraform documentation workflow.

## Scope

The change covers the root README, the `oidc-provider` module README, a new `docs/` documentation set, repository-wide agent guidance, and the existing `terraform-docs.yml` workflow from the canonical `main` branch. It does not change Terraform resources or deployment behavior.

## Security and Privacy

The repository-root `AGENTS.md` will establish that documentation, examples, generated output, logs, and commit messages must not contain AWS account IDs, credentials, tokens, private keys, full resource identifiers, full ARNs, state bucket names, or other sensitive values. Documentation will use placeholders and logical resource descriptions instead.

The AWS-derived workflow output will redact sensitive fields before writing Markdown. The root README will describe the state backend and state keys without exposing the actual bucket name or account identifier.

## Documentation Structure

The root README will contain these sections:

- Deployed Infrastructure
- Estimated Monthly Cost
- Repo Layout
- Remote State
- Quick Start
- Documentation
- Verification

The deployed infrastructure section will describe the AWS region and the safe logical categories discovered through AWS APIs: S3 remote state, GitHub Actions OIDC, the GitHub Actions IAM role, and AWS Budgets.

The cost section will use AWS Cost Explorer actual and forecast data. Values will be displayed in AUD using the documented fixed conversion rate `USD 1.00 = AUD 1.55`. It will identify the value as account-level forecast data without publishing the account identifier or a generated timestamp.

The remote-state table will list logical Terraform roots and their keys:

| Root | State key |
| --- | --- |
| `bootstrap/account` | `bootstrap/account/terraform.tfstate` |
| `environments/test` | `environments/test/terraform.tfstate` |

The module README will retain a concise introduction, usage example with placeholders, security notes, and references while receiving requirements, resources, inputs, and outputs from `terraform-docs` markers.

The `docs/` directory will contain:

- `getting-started.md` for credentials, backend setup, Terraform commands, and CI behavior.
- `architecture.md` for the bootstrap stack, test environment, OIDC trust flow, and state layout.
- `verification.md` for validation commands, API sources, redaction rules, and cost assumptions.

## Automation

The existing `.github/workflows/terraform-docs.yml` from the canonical repository will be adapted rather than creating a second documentation workflow or a standalone script. The workflow will:

1. Run `terraform-docs` for directories under `modules/`.
2. Assemble generated module content into marked sections in the root README using inline workflow logic.
3. Query AWS CLI APIs for safe live infrastructure and Cost Explorer data when credentials are available.
4. Convert cost output to AUD at the fixed `1.55` rate.
5. Redact account IDs, ARNs, bucket names, and resource IDs before writing files.
6. Commit only changed documentation using the repository's existing signed-commit pattern.

The workflow will support pull-request updates and post-merge updates to `main` as permitted by repository permissions and branch protection. Generated timestamps will not be included.

## Verification

Validation will use Terraform Registry documentation for the `hashicorp/aws` provider, Terraform formatting and validation, TFLint, Checkov, AWS CLI or AWS MCP read-only API calls, and the Terraform Best Practices MCP endpoint:

`https://www.terraform-best-practices.com/~gitbook/mcp`

The final README verification section will list only tools actually used during implementation.
