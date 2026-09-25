# Repository Guidance

## Active Scope

- Normal work is limited to `environments/test/` and `modules/oidc-provider/`.
- `bootstrap/account/` was used for the initial deployment and is not in active use. Do not plan, change, deploy, or rely on it unless the user explicitly asks.
- `environments/test/` is the active root. Keep its S3 backend key unique and keep `use_lockfile = true` for native state locking.
- This repository does not use HCP Terraform for state or runs.

## Required Workflow

- Before a non-trivial feature, refactor, or infrastructure change, write a dated plan in `plans/`.
- Get the repository owner's approval and land the plan through a PR before implementation.
- Keep each new plan and report under 500 words, including references.
- Add a `References` section to every new plan and report. Prefer official documentation, engineering blogs. Do not use academic papers.
- Put reports in `reports/` and link the plan, PR, and commits.
- Use simple English in all documentation, plans, reports, README files, code comments, commit messages, PR titles, and PR descriptions, including this file.
- Do not commit `.tfvars`, Terraform state, plan files, credentials, or other secrets.

## AWS Tools

- Use the AWS CLI or direct AWS API tools first for live AWS reads and account operations. Start with `aws sts get-caller-identity` when the target account is uncertain.
- Use `aws-knowledge` only for official AWS documentation, API behavior, regional availability, AWS best practices, and AWS agent skills. Do not use it to inspect account state. The AWS knowledge MCP endpoint is `https://knowledge-mcp.global.api.aws`; use its `aws___search_documentation` and `aws___read_documentation` tools.
- Use `aws-mcp` only when the AWS CLI or API tools are unavailable, or when the task specifically needs MCP sandboxing or audit features.
- Keep AWS calls read-only unless the user explicitly approves a change.
- Redact account IDs, ARNs, resource IDs, state bucket names, credentials, and sensitive API output before writing it to a file, log, commit message, or PR.
- Do not call Cost Explorer during routine checks because it costs money. Use an existing documented snapshot unless the user approves a new paid query.

## Terraform MCP Tools

- Use `terraform` before changing Terraform to verify provider resources, data sources, modules, and policies in the Terraform Registry.
- Use `terraform-best-practices` before changing Terraform structure, module boundaries, naming, documentation, or backend conventions.
- Do not use either Terraform MCP server for HCP Terraform state or run operations.
- Use local commands for final verification. MCP output does not replace `terraform fmt`, `terraform validate`, TFLint, Checkov, or CI.
- Document only tools and checks that were actually used.

## Verification

For changes to Terraform files, run the checks for each changed active root or module. Start with:

```bash
terraform fmt -check -recursive
tflint --init
tflint --recursive --format compact
```

Then run `init -backend=false`, `validate`, and Checkov for the changed directory:

```bash
terraform -chdir=environments/test init -backend=false
terraform -chdir=environments/test validate
checkov -d environments/test --config-file .checkov.yml

terraform -chdir=modules/oidc-provider init -backend=false
terraform -chdir=modules/oidc-provider validate
checkov -d modules/oidc-provider --config-file .checkov.yml
```

- For documentation, `AGENTS.md`, or MCP configuration changes, check the changed file format and inspect the diff. Terraform checks are not required.
- Do not push Terraform code that fails these checks. Fix the cause first.
- Do not hand-edit Terraform-generated README blocks. Use `terraform-docs` and keep the generated markers intact.

## Git and PR Rules

- Never force-push. `git push --force` is forbidden. Use `--force-with-lease` only when a force update is unavoidable.
- When review requests changes, add a new commit and push it normally.
- Always use the repository's pull request template (`.github/pull_request_template.md`) when submitting a pull request.
- Rebase the PR branch onto the latest base branch and push before opening or updating a pull request, so the branch is never out of date at merge time.
- Every PR must list `rzkw` as a reviewer. Keep `* @rzkw` in `.github/CODEOWNERS`; restore the file if it is missing. Never remove that rule.
- Sign every commit with `~/.ssh/agent-gh-signing` and verify the signature before pushing.
