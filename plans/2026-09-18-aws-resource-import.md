# AWS Resource Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three independent Terraform roots that describe the existing AWS VPC, IAM, and budget resources and provide import commands without executing imports.

**Architecture:** Use `environments/test/vpc`, `environments/test/iam`, and `environments/test/budgets` as independent roots with separate backend keys. Live AWS state is authoritative; the unmerged `aws` branch of `oci-cloudinfra` is used only as a starting point for the budgets module. The existing main route table remains the VPC main route table.

**Tech Stack:** Terraform >= 1.5, AWS provider `~> 6.0`, AWS CLI, terraform-docs, GitHub Actions.

## Global Constraints

- Do not execute this plan, initialize configured remote backends, import resources, or apply changes before explicit admin approval and merge to `main`.
- Do not commit credentials, account IDs, email addresses, `.tfvars`, state files, or generated secrets.
- Keep VPC, IAM, and budgets in independent Terraform states.
- Use the existing VPC main route table; do not create a replacement route table.
- Provider credentials must come from the environment or AWS profile, not hard-coded `profile` arguments.

---

## File Structure

| File | Action | Purpose |
|---|---|---|
| `environments/test/vpc/*.tf` | Create | VPC, subnet, and existing main route table |
| `environments/test/vpc/imports.tf` | Create | Declarative import blocks for VPC resources |
| `environments/test/iam/*.tf` | Create | Users, groups, memberships, and all managed policy attachments |
| `environments/test/iam/imports.tf` | Create | Declarative import blocks for IAM resources |
| `environments/test/budgets/*.tf` | Create | Two existing AWS budgets and their live notification thresholds |
| `environments/test/budgets/imports.tf` | Create | Declarative import blocks for budgets |
| `IMPORT.md` | Create | Read-only discovery and administrator-run import workflow |
| `.github/workflows/terraform-docs.yml` | Create | Copy source docs workflow; use `find-dir: environments/test/**` |
| `README.md` | Modify | Add docs markers for the three generated module sections |
| `plans/2026-09-18-aws-resource-import.md` | Create | This approval-gated implementation plan |

### Task 1: Add the independent Terraform roots

- [ ] Create provider, backend, resource, and `imports.tf` files for each root. Follow Terraform’s documented convention of collecting import blocks in `imports.tf`.
- [ ] Use separate state keys such as `environments/test/vpc/terraform.tfstate`, `environments/test/iam/terraform.tfstate`, and `environments/test/budgets/terraform.tfstate`.
- [ ] Define the live resources: one VPC, one subnet, and the existing main route table; users `agent-walkllc` and `rzkw-iam`; groups `admin` and `read-only`; two `aws_iam_user_group_membership` resources; and seven AWS-managed policy attachments.
- [ ] Use variables for discovered VPC, subnet, route-table, and account IDs in `imports.tf`; do not hard-code account identifiers. Use individual `import` blocks whose `to` addresses exactly match the resource addresses.
- [ ] Do not add `aws_main_route_table_association`: its provider documentation does not define an import format. Verify the imported route table is already the VPC main table with AWS CLI before import.
- [ ] Base budgets on `oci-cloudinfra` branch `aws/terraform/aws/budgets`, correcting it to match live state: `monthly-budget` at 50% forecasted and 80%/90% actual notifications, and `zero-spend` at the live absolute threshold. Do not copy its email placeholder.

### Task 2: Add non-executing import commands

- [ ] Create one root-level `IMPORT.md`, not one file per root.
- [ ] Document read-only ID discovery using `AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"`, VPC filters, subnet filters, and the main-route-table filter.
- [ ] Document setting the discovered values as `TF_VAR_*` variables, then running `terraform init`, `terraform plan`, and `terraform apply` separately in each root. `terraform apply` is the operation that executes the `imports.tf` blocks.
- [ ] Document that `imports.tf` must remain present during the import plan/apply and that the user must review the plan before applying. Do not execute these commands before explicit admin approval and merge to `main`.

`IMPORT.md` must contain commands equivalent to the following, with no literal account ID, resource ID, email address, or secret:

```bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

VPC_ID="$(aws ec2 describe-vpcs --filters Name=cidr-block,Values=10.0.0.0/16 --query 'Vpcs[0].VpcId' --output text)"
SUBNET_ID="$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" Name=cidr-block,Values=10.0.0.0/24 --query 'Subnets[0].SubnetId' --output text)"
ROUTE_TABLE_ID="$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" Name=association.main,Values=true --query 'RouteTables[0].RouteTableId' --output text)"
export TF_VAR_vpc_id="$VPC_ID"
export TF_VAR_subnet_id="$SUBNET_ID"
export TF_VAR_route_table_id="$ROUTE_TABLE_ID"
export TF_VAR_account_id="$AWS_ACCOUNT_ID"

terraform -chdir=environments/test/vpc init
terraform -chdir=environments/test/vpc plan
terraform -chdir=environments/test/vpc apply

```
Repeat the above plan/apply for each module. 


The corresponding `imports.tf` files must use Terraform import blocks such as `import { to = aws_vpc.this id = var.vpc_id }`, `import { to = aws_iam_user.this["agent-walkllc"] id = "agent-walkllc" }`, `import { to = aws_iam_user_group_membership.this["agent-walkllc/read-only"] id = "agent-walkllc/read-only" }`, and `import { to = aws_budgets_budget.this["monthly-budget"] id = "${var.account_id}:monthly-budget" }`.

### Task 3: Add docs automation

- [ ] Copy the referenced workflow exactly, changing `find-dir` to `environments/test/**`.
- [ ] Change only the assembly glob needed for this layout from `terraform/*/README.md` to `environments/test/*/README.md`; retain the source workflow’s signing, checkout, permissions, and commit behavior.
- [ ] Add stable README markers for `vpc`, `iam`, and `budgets`.

### Task 4: Validate without touching remote state

- [ ] Run `terraform fmt -check -recursive`.
- [ ] Run `terraform init -backend=false` and `terraform validate` separately for all three roots.
- [ ] Run TFLint and Checkov using the repository’s existing configuration.
- [ ] Confirm no import, apply, remote-backend initialization, or state mutation occurred.

## References

- Source AWS Terraform: https://github.com/rzkw/oci-cloudinfra/tree/aws/terraform/aws
- Source docs workflow: https://raw.githubusercontent.com/rzkw/oci-cloudinfra/refs/heads/main/.github/workflows/terraform-docs.yml
- AWS provider resources: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Terraform import blocks: https://developer.hashicorp.com/terraform/language/block/import
- AWS route table import: https://github.com/hashicorp/terraform-provider-aws/blob/main/website/docs/r/route_table.html
- AWS IAM membership import: https://github.com/hashicorp/terraform-provider-aws/blob/main/website/docs/r/iam_user_group_membership.html
- AWS IAM attachment imports: https://github.com/hashicorp/terraform-provider-aws/blob/main/website/docs/r/iam_group_policy_attachment.html
- AWS budgets import: https://github.com/hashicorp/terraform-provider-aws/blob/main/website/docs/r/budgets_budget.html
