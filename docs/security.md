# Security

This repository uses short-lived AWS credentials for CI and keeps Terraform state in S3. Keep permissions narrow and keep sensitive values out of Git.

## CI access

- GitHub Actions uses OIDC to exchange a signed token for temporary AWS credentials. Workflows do not need long-lived AWS access keys.
- The role trust policy checks the repository subject and the `sts.amazonaws.com` audience. Keep the repository, branch, and environment scope as narrow as practical.
- Keep `id-token: write` only for jobs that assume the AWS role.
- Review the managed and inline policies attached to the CI role. Grant only the actions needed by the test environment.
- Pull requests may run validation and plans; apply runs only from `main`. Do not broaden that boundary without reviewing the trust policy.

## Human and account access

- Prefer IAM Identity Center or another identity provider for human access, with temporary credentials.
- Do not use the AWS root user for routine work. Protect root credentials and any required long-term credentials with MFA, and keep them outside the repository.
- Review and remove unused IAM users, roles, policies, and access keys. Use last-accessed data and IAM Access Analyzer when available.

## Local access

- Run `aws sts get-caller-identity` before making changes and confirm the account and role match the target environment.
- Never commit credentials, tokens, private keys, `.tfvars`, state files, or plan files.
- Pass Terraform values through `TF_VAR_*` environment variables or CLI flags.

## Terraform state

- State is stored in encrypted and versioned S3 with native `.tflock` locking.
- Every Terraform root must set an explicit state `key` so roots cannot share the default `terraform.tfstate` file.
- Do not expose state bucket names or other sensitive AWS identifiers in documentation.

## Checks and documentation

- TFLint and Checkov run as required CI checks. If either check fails, deployment stops.
- Never write credentials, tokens, private keys, account IDs, ARNs, resource IDs, or state bucket names to repository files.
- Use placeholders such as `<aws-account-id>`, `<state-bucket>`, and `<role-arn>` in examples, and redact AWS output before saving it.
- Follow the repository rules in [AGENTS.md](../AGENTS.md).

## References

- [AWS IAM security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.md)
