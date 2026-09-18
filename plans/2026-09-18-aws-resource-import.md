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
| `environments/test/vpc/*.tf` | Create | VPC, subnet, route table, and main-route-table association |
| `environments/test/iam/*.tf` | Create | Users, groups, memberships, and all managed policy attachments |
| `environments/test/budgets/*.tf` | Create | Two existing AWS budgets and their live notification thresholds |
| `environments/test/{vpc,iam,budgets}/IMPORT.md` | Create | Read-only discovery and administrator-run import commands |
| `.github/workflows/terraform-docs.yml` | Create | Copy source docs workflow; use `find-dir: environments/test/**` |
| `README.md` | Modify | Add docs markers for the three generated module sections |
| `plans/2026-09-18-aws-resource-import.md` | Create | This approval-gated implementation plan |

### Task 1: Add the independent Terraform roots

- [ ] Create provider, backend, and resource files for each root.
- [ ] Use separate state keys such as `environments/test/vpc/terraform.tfstate`, `environments/test/iam/terraform.tfstate`, and `environments/test/budgets/terraform.tfstate`.
- [ ] Define the live resources: one VPC, one subnet, one route table plus main association; users `agent-walkllc` and `rzkw-iam`; groups `admin` and `read-only`; their existing memberships and seven AWS-managed policy attachments.
- [ ] Base budgets on `oci-cloudinfra` branch `aws/terraform/aws/budgets`, correcting it to match live state: `monthly-budget` at 50% forecasted and 80%/90% actual notifications, and `zero-spend` at the live absolute threshold. Do not copy its email placeholder.

### Task 2: Add non-executing import commands

- [ ] Add `IMPORT.md` under each root with commands that first derive IDs using read-only AWS CLI queries and `AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)`.
- [ ] Import VPC, subnet, route table, and main association by discovered IDs.
- [ ] Import users, groups, memberships (`group/user`), and all group/user policy attachments using their AWS-managed policy ARNs.
- [ ] Import budgets using `account-id:budget-name` values produced at runtime.
- [ ] State clearly that each command requires `terraform init` against the administrator’s configured backend and must not be run before merge approval.

Each `IMPORT.md` must contain commands equivalent to the following, with no literal account ID or secret:

```bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

VPC_ID="$(aws ec2 describe-vpcs --filters Name=cidr-block,Values=10.0.0.0/16 --query 'Vpcs[0].VpcId' --output text)"
SUBNET_ID="$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" Name=cidr-block,Values=10.0.0.0/24 --query 'Subnets[0].SubnetId' --output text)"
ROUTE_TABLE_ID="$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" Name=association.main,Values=true --query 'RouteTables[0].RouteTableId' --output text)"
terraform -chdir=environments/test/vpc import aws_vpc.this "$VPC_ID"
terraform -chdir=environments/test/vpc import aws_subnet.this "$SUBNET_ID"
terraform -chdir=environments/test/vpc import aws_route_table.this "$ROUTE_TABLE_ID"
terraform -chdir=environments/test/vpc import aws_main_route_table_association.this "$VPC_ID"

terraform -chdir=environments/test/iam import 'aws_iam_user.this["agent-walkllc"]' agent-walkllc
terraform -chdir=environments/test/iam import 'aws_iam_user.this["rzkw-iam"]' rzkw-iam
terraform -chdir=environments/test/iam import 'aws_iam_group.this["admin"]' admin
terraform -chdir=environments/test/iam import 'aws_iam_group.this["read-only"]' read-only
terraform -chdir=environments/test/iam import 'aws_iam_group_membership.this["admin/rzkw-iam"]' admin/rzkw-iam
terraform -chdir=environments/test/iam import 'aws_iam_group_membership.this["read-only/agent-walkllc"]' read-only/agent-walkllc
terraform -chdir=environments/test/iam import 'aws_iam_group_policy_attachment.this["admin/AdministratorAccess"]' 'admin/arn:aws:iam::aws:policy/AdministratorAccess'
terraform -chdir=environments/test/iam import 'aws_iam_group_policy_attachment.this["admin/SystemAdministrator"]' 'admin/arn:aws:iam::aws:policy/job-function/SystemAdministrator'
terraform -chdir=environments/test/iam import 'aws_iam_group_policy_attachment.this["admin/DatabaseAdministrator"]' 'admin/arn:aws:iam::aws:policy/job-function/DatabaseAdministrator'
terraform -chdir=environments/test/iam import 'aws_iam_group_policy_attachment.this["admin/NetworkAdministrator"]' 'admin/arn:aws:iam::aws:policy/job-function/NetworkAdministrator'
terraform -chdir=environments/test/iam import 'aws_iam_group_policy_attachment.this["read-only/ReadOnlyAccess"]' 'read-only/arn:aws:iam::aws:policy/ReadOnlyAccess'
terraform -chdir=environments/test/iam import 'aws_iam_user_policy_attachment.this["rzkw-iam/IAMUserChangePassword"]' 'rzkw-iam/arn:aws:iam::aws:policy/IAMUserChangePassword'
terraform -chdir=environments/test/iam import 'aws_iam_user_policy_attachment.this["rzkw-iam/SignInLocalDevelopmentAccess"]' 'rzkw-iam/arn:aws:iam::aws:policy/SignInLocalDevelopmentAccess'

terraform -chdir=environments/test/budgets import 'aws_budgets_budget.this["monthly-budget"]' "$AWS_ACCOUNT_ID:monthly-budget"
terraform -chdir=environments/test/budgets import 'aws_budgets_budget.this["zero-spend"]' "$AWS_ACCOUNT_ID:zero-spend"
```

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
- Terraform import: https://developer.hashicorp.com/terraform/cli/import
