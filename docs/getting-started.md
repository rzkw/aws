# Getting Started

## Prerequisites

- AWS account with credentials for the target account
- GitHub repository admin access
- Development tools: `make install-tools` installs Terraform, AWS CLI, jq, TFLint, and Checkov

## Configure AWS Credentials

```bash
# Verify your identity
aws sts get-caller-identity
```

The account and role resolved must match the target environment. Never commit credentials.

## Bootstrap

```bash
make setup
```

`setup.sh` verifies prerequisites, creates the S3 backend bucket with native state locking, creates the account bootstrap stack (shared OIDC provider), generates environment configurations, and writes the environment-to-account mapping in `config/environments.json`.

## Deploy

Per-root initialization and apply:

```bash
terraform -chdir=bootstrap/account init
terraform -chdir=bootstrap/account apply

terraform -chdir=environments/test init
terraform -chdir=environments/test apply
```

No `.tfvars` files are committed; set variables via environment (`TF_VAR_*`) or CLI flags.

## CI/CD

Merges to `main` trigger the test environment deploy workflow:

1. TFLint and Checkov scans run fail-closed.
2. Terraform plan is posted to pull requests for review.
3. Apply runs on push to `main` using OIDC authentication (no long-lived keys).

## Maintenance

- `make validate-full` — format check, per-environment validate, TFLint, and Checkov
- `make plan ENV=test` / `make apply ENV=test` — targeted runs
- `make cleanup` — interactive cleanup script