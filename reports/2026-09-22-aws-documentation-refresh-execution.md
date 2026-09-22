# Execution Report: AWS Documentation Refresh

Documents execution of the approved plan
[`docs/superpowers/plans/2026-09-18-aws-documentation-refresh.md`](../docs/superpowers/plans/2026-09-18-aws-documentation-refresh.md)
and design
[`docs/superpowers/specs/2026-09-18-aws-documentation-refresh-design.md`](../docs/superpowers/specs/2026-09-18-aws-documentation-refresh-design.md).

**Goal:** Replace the starter-kit README with accurate, sensitive-value-safe
documentation for the deployed AWS infrastructure, add focused `docs/` guidance,
give the `oidc-provider` module an updated README, and keep module docs current
through the existing `terraform-docs.yml` workflow.

## What Was Implemented

- Root `README.md` - replaced the starter-kit marketing content with the
  required sections: Deployed Infrastructure, Estimated Monthly Cost, Repo
  Layout, Remote State (and keys table), Quick Start, Documentation, and
  Verification. Sensitive identifiers (account IDs, ARNs, resource IDs, state
  bucket name) are omitted.
- `modules/oidc-provider/README.md` - short description, placeholder-based
  usage example, security considerations, and terraform-docs-generated
  Requirements / Providers / Resources / Inputs / Outputs.
- `docs/getting-started.md`, `docs/architecture.md`, `docs/verification.md` -
  credentials, deployment workflow, architecture (with trust-flow diagram),
  remote-state layout, verification commands, and the fixed AUD conversion
  policy.
- `AGENTS.md` - repository-wide policy: never include AWS account IDs or
  secrets in docs, examples, generated output, logs, or commit messages; use
  placeholders; prefer the Terraform Best Practices MCP endpoint; document only
  tools actually used.
- `.github/workflows/terraform-docs.yml` - adapted from the existing OCI-derived
  workflow: `find-dir` retargeted to `modules/**`, assembly glob changed to
  `modules/*/README.md`, added `push: main` and `workflow_dispatch` triggers so
  module docs auto-update on merge to `main`, and `git add` includes
  `modules/*/README.md`. Inline Python assembly retained; **no standalone script
  added**.

## Note: AWS Cost Explorer Is Not Queried in CI

AWS Cost Explorer is intentionally **not** called during documentation refresh.
**Each Cost Explorer API call incurs a cost**, so the estimated-monthly-cost
figure in the root README is a **manual read-only snapshot** (captured during
this session) rather than an automated query. It is refreshed on an as-needed
basis, uses the fixed documented rate **US$1.00 = A$1.55**, and reports no
generated timestamp.

## What Was Verified

- `terraform fmt -check -recursive` - clean.
- `terraform init -backend=false` + `terraform validate` - valid for
  `modules/oidc-provider`, `environments/test`, and `bootstrap/account`
  (Terraform v1.16.0, provider `hashicorp/aws ~> 5.0`). Validation-only
  lockfile changes were reverted.
- `tflint --recursive --format compact` - clean (exit 0).
- `checkov -d . --config-file .checkov.yml` - failures are the pre-existing
  live-posture set already documented in the import execution report (IAM users
  instead of SSO, `AdministratorAccess` on admin/OIDC roles, VPC without flow
  logging, public IP on subnet, missing NAT default route, OIDC wildcard
  claims). None are introduced by this documentation change; no `.tf` files were
  modified.
- `terraform-docs v0.19.0` - module README section generated and assembled into
  the root README; marker replacement verified locally.
- **Terraform Best Practices MCP** (`https://www.terraform-best-practices.com/~gitbook/mcp`,
  v0.27.2) - `searchDocumentation` used to confirm naming and code-structure
  conventions against the generated README.
- Workflow YAML parsed successfully.
- Sensitive-value scan - no new account-ID literals, ARNs, bucket names, keys,
  or tokens in `README.md`, `docs/`, `modules/`, or the workflow (remaining
  matches are policy text, the scan regex itself, and pre-existing
  `terraform-deploy-test.yml` values untouched by this change).

## Not Executed

- No AWS Cost Explorer API calls were made during CI/workflow execution (see
  Note above); AWS facts are a manual, redacted snapshot.
- No backend initialization, import, or apply was performed.