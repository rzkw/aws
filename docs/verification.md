# Verification

## Tool Sources

- **Terraform Registry** — `hashicorp/aws` provider documentation for resource and data-source types used by the modules (`https://registry.terraform.io/providers/hashicorp/aws/latest`).
- **Terraform Best Practices MCP** — README structure, naming, and backend conventions validated at `https://www.terraform-best-practices.com/~gitbook/mcp`.
- **AWS CLI** — read-only confirmation of live resources (identifiers redacted). Prefer the AWS MCP server when available.

## Commands

```bash
# Format check across all roots
terraform fmt -check -recursive

# Validate each root (backend-free)
terraform -chdir=modules/oidc-provider init -backend=false
terraform -chdir=modules/oidc-provider validate
terraform -chdir=environments/test init -backend=false
terraform -chdir=environments/test validate
terraform -chdir=bootstrap/account init -backend=false
terraform -chdir=bootstrap/account validate

# Lint and security
tflint --recursive --format compact
checkov -d . --config-file .checkov.yml
```

## Cost Estimates

Estimated monthly cost uses a **fixed documented conversion rate** of US$1.00 = A$1.55.

AWS Cost Explorer is **not** queried during documentation refresh: each Cost Explorer API call incurs a charge. Cost figures in the README are a manual snapshot captured read-only and are refreshed on an as-needed basis.

## AWS Fact Sources

| Fact | Source |
| --- | --- |
| OIDC provider / IAM role | `aws iam list-open-id-connect-providers`, `aws iam get-role` |
| S3 state bucket | `aws s3api get-bucket-versioning`, `get-bucket-encryption` |
| Budgets | `aws budgets describe-budgets` |
| Cost snapshot | AWS Cost Explorer (manual, read-only; not run in CI) |

Sensitive outputs (account IDs, ARNs, resource IDs, bucket names) are redacted before any value is written to repository files.