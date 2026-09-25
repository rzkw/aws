# Security

This repository uses short-lived AWS credentials and keeps sensitive values out of documentation.

## CI Authentication

- GitHub Actions uses OIDC to sign in to AWS.
- The trust policy is limited to this repository and accepts the audience `sts.amazonaws.com`.
- Workflows do not need long-lived AWS access keys.

## Local Setup

- Run `aws sts get-caller-identity` before making changes and confirm the account and role match the target environment.
- Never commit AWS credentials or `.tfvars` files.
- Pass Terraform values through environment variables such as `TF_VAR_*` or through CLI flags.

## State Protection

Terraform state is stored in S3 in `us-east-1` with server-side encryption (AES256), versioning, and native `.tflock` locking.

Every Terraform root must set an explicit state `key`. Without one, Terraform uses `terraform.tfstate`, so different roots could share the same state.

## Required Checks

TFLint and Checkov run in CI as required checks. If either check fails, deployment stops.

## Documentation Safety

- Never write credentials, tokens, private keys, account IDs, ARNs, resource IDs, or state bucket names to repository files.
- Use placeholders such as `<aws-account-id>`, `<state-bucket>`, and `<role-arn>` in examples.
- Redact AWS output before saving it.
- Follow the repository rules in [AGENTS.md](../AGENTS.md).

## Related Documentation

- [Getting Started](getting-started.md)
- [Architecture](architecture.md)
- [Verification](verification.md)
