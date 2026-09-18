# Repository Guidance

## Documentation Safety

- Never include AWS account IDs in documentation, examples, generated output, logs, or commit messages.
- Never include credentials, tokens, private keys, passwords, or other secrets.
- Do not include full AWS ARNs, resource IDs, state bucket names, or backend secrets in documentation unless they are explicitly classified as safe.
- Use placeholders such as `<aws-account-id>`, `<state-bucket>`, and `<role-arn>` in examples.
- Redact sensitive values returned by AWS APIs before writing them to repository files.

## Validation

- Prefer the Terraform Best Practices MCP endpoint at `https://www.terraform-best-practices.com/~gitbook/mcp` for Terraform documentation and best-practice validation.
- Prefer the AWS MCP server for AWS read-only interactions; use the AWS CLI directly when the MCP server is unavailable.
- Document only tools and checks that were actually used.
