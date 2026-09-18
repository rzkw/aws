# AWS Resource Import

This file describes the administrator-run workflow for importing the existing
AWS resources into the three independent Terraform states managed by this
repository:

- `environments/test/vpc` - VPC, subnet, and the existing VPC main route table
- `environments/test/iam` - IAM users, groups, memberships, and AWS-managed policy attachments
- `environments/test/budgets` - the two existing AWS budgets

Each root declares its own `imports.tf` file with Terraform `import` blocks.
The import blocks execute during `terraform apply`; they do not run during
`terraform plan`.

> **GATE**: Do not run these commands until the implementation PR is approved
> and merged to `main`, and confirm the target backend keys
> (`environments/test/{vpc,iam,budgets}/terraform.tfstate`) are empty before
> starting. This workflow initializes the remote S3 backends and imports live
> resources into state.

## Prerequisites

- Terraform >= 1.10
- AWS CLI v2 with credentials for the owning account (e.g. the `default` profile)
- No existing state in the target backend keys

## 1. Read-only ID discovery

```bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

VPC_ID="$(aws ec2 describe-vpcs --filters Name=cidr-block,Values=10.0.0.0/16 --query 'Vpcs[0].VpcId' --output text)"
SUBNET_ID="$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" Name=cidr-block,Values=10.0.0.0/24 --query 'Subnets[0].SubnetId' --output text)"
ROUTE_TABLE_ID="$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" Name=association.main,Values=true --query 'RouteTables[0].RouteTableId' --output text)"
```

Confirm the discovered route table is the VPC main route table:

```bash
aws ec2 describe-route-tables --route-table-ids "$ROUTE_TABLE_ID" --query 'RouteTables[0].Associations[].Main'
```

## 2. Export import variables

```bash
export TF_VAR_vpc_id="$VPC_ID"
export TF_VAR_subnet_id="$SUBNET_ID"
export TF_VAR_route_table_id="$ROUTE_TABLE_ID"
export TF_VAR_account_id="$AWS_ACCOUNT_ID"
```

Optional: the live budgets currently have no subscribers, so the budget
notification blocks manage an empty subscriber list by default. If the budget
notifications should manage subscribers, set `TF_VAR_budget_subscriber_emails`
to the desired list of addresses before the budgets apply step. The AWS
provider requires at least one subscriber before it can update a notification.

## 3. Import per root (init, review plan, apply)

Run the roots in this order: `vpc`, then `iam`, then `budgets`.

```bash
terraform -chdir=environments/test/vpc init
terraform -chdir=environments/test/vpc plan
terraform -chdir=environments/test/vpc apply

terraform -chdir=environments/test/iam init
terraform -chdir=environments/test/iam plan
terraform -chdir=environments/test/iam apply

terraform -chdir=environments/test/budgets init
terraform -chdir=environments/test/budgets plan
terraform -chdir=environments/test/budgets apply
```

Review every `plan` output before applying. The `imports.tf` files must remain
present during this workflow; after the resources are imported, the plans
should show no changes.

## 4. Verify

```bash
terraform -chdir=environments/test/vpc state list
terraform -chdir=environments/test/iam state list
terraform -chdir=environments/test/budgets state list

terraform -chdir=environments/test/vpc plan
terraform -chdir=environments/test/iam plan
terraform -chdir=environments/test/budgets plan
```

All three plans should report no changes once the import is complete.

## Notes

- The existing route table is already the VPC main route table. No
  `aws_main_route_table_association` resource is defined because its provider
  documentation does not define an import format.
- No literal account ID, resource ID, email address, or secret appears in the
  repository; all identifiers above are discovered at runtime.