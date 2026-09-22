# Architecture

```mermaid
graph LR
  subgraph CI[GitHub Actions]
    WF[Workflow]
  end
  subgraph AWS[AWS Account]
    OIDC[OIDC Provider]
    ROLE[GitHub Actions IAM Role]
    STACK[Env Stacks: VPC, IAM, Budgets]
    BUCKET[S3 State Bucket]
  end

  WF -- OIDC token --> OIDC
  OIDC -- trust --> ROLE
  ROLE -- assumed --> WF
  WF -- apply --> STACK
  TF[Terraform] -. state read/write .-> BUCKET
```

## Bootstrap Stack (`bootstrap/account`)

- Creates the GitHub Actions OIDC provider (`token.actions.githubusercontent.com`) unless an existing provider is reused.
- The provider is shared across account stacks.

## Environments (`environments/test`)

- Root config consumes `modules/oidc-provider` to create the `GitHubActionsServiceRole-Terraform` role.
- The role trust policy allows `sts:AssumeRoleWithWebIdentity` for the repository subject with audience `sts.amazonaws.com`.
- Additional roots describe the deployed VPC, IAM users/groups, and budgets, imported from live state.

## Remote State

- S3 bucket in `us-east-1`, server-side encrypted (AES256), versioning enabled, native `.tflock` locking.
- Each root uses an explicit key:

| Root | State key |
| --- | --- |
| `bootstrap/account` | `bootstrap/account/terraform.tfstate` |
| `environments/test` | `environments/test/terraform.tfstate` |

## OIDC Trust Flow

1. GitHub Actions requests a signed OIDC token for the job.
2. AWS is asked to exchange the token via `sts:AssumeRoleWithWebIdentity`.
3. The IAM role trust policy validates subject (`repo:<owner>/<repo>:*`) and audience (`sts.amazonaws.com`).
4. The workflow receives temporary credentials and deploys without static keys.