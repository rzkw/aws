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