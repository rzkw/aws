# AWS Documentation Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the starter-kit README with safe, live AWS infrastructure documentation and automate module documentation updates through the existing Terraform documentation workflow.

**Architecture:** Keep curated prose in the root and module READMEs, with Terraform-generated sections bounded by `terraform-docs` markers. Adapt the existing inline workflow pattern to generate module docs, assemble the root README, and refresh redacted AWS Cost Explorer and infrastructure sections without adding a standalone script.

**Tech Stack:** Markdown, GitHub Actions, `terraform-docs/gh-actions`, AWS CLI, AWS Cost Explorer, Terraform, TFLint, Checkov, Terraform Best Practices MCP.

## Global Constraints

- Never include AWS account IDs, credentials, tokens, private keys, full ARNs, resource IDs, state bucket names, or other sensitive values in documentation, examples, generated output, logs, or commit messages.
- Use placeholders such as `<aws-account-id>`, `<state-bucket>`, and `<role-arn>` in examples.
- Do not add a standalone documentation script.
- Do not include generated timestamps.
- Display cost estimates in AUD using `USD 1.00 = AUD 1.55`.
- Adapt the existing `.github/workflows/terraform-docs.yml`; do not create a second documentation workflow.
- Validate Terraform guidance with `https://www.terraform-best-practices.com/~gitbook/mcp` and list only tools actually used in the final verification section.

---

### Task 1: Record Repository Policy and Design

**Files:**
- Create: `AGENTS.md`
- Create: `specs/2026-09-18-aws-documentation-refresh-design.md`
- Create: `plans/2026-09-18-aws-documentation-refresh.md`

**Interfaces:**
- Produces repository-wide documentation safety rules consumed by all later tasks.

- [ ] **Step 1: Add root agent guidance**

Create `AGENTS.md` with the sensitive-value prohibition, placeholder policy, preference for AWS MCP with AWS CLI fallback, and the Terraform Best Practices MCP endpoint.

- [ ] **Step 2: Self-review the design and plan**

Check both documents for missing requirements, contradictory workflow behavior, account identifiers, and placeholder markers. Confirm every approved requirement maps to at least one later task.

- [ ] **Step 3: Commit the planning documents**

```bash
git add AGENTS.md specs/2026-09-18-aws-documentation-refresh-design.md plans/2026-09-18-aws-documentation-refresh.md
git commit -S -m "docs: plan AWS documentation refresh"
```

### Task 2: Write Repository Documentation

**Files:**
- Modify: `README.md`
- Modify: `modules/oidc-provider/README.md`
- Create: `docs/getting-started.md`
- Create: `docs/architecture.md`
- Create: `docs/verification.md`

**Interfaces:**
- Consumes the repository policy from `AGENTS.md`.
- Produces safe human-authored content and generated-section markers for the workflow.

- [ ] **Step 1: Replace starter-kit root content**

Rewrite `README.md` around the required sections: deployed infrastructure, estimated monthly cost, repository layout, remote state and keys, quick start, documentation, and verification. Use logical resource descriptions and placeholders only. Include the state key table without the real bucket name or account ID.

- [ ] **Step 2: Add generated section markers**

Add stable markers for the deployed infrastructure, cost, and `oidc-provider` generated content. Keep curated headings and explanatory notes outside generated ranges so the workflow can replace only generated content.

- [ ] **Step 3: Update the module README**

Retain the module description, usage, security considerations, and references. Add `terraform-docs` markers for requirements, resources, inputs, and outputs. Change examples to placeholders rather than real role ARNs or account IDs.

- [ ] **Step 4: Create focused documentation pages**

Write `docs/getting-started.md`, `docs/architecture.md`, and `docs/verification.md` with commands and diagrams/tables as appropriate. Use placeholder backend values and document the fixed AUD conversion policy and Terraform Best Practices MCP endpoint.

- [ ] **Step 5: Run Markdown secret-safety checks**

Run:

```bash
rg -n "<aws-account-id>|arn:aws:|terraform-state-[0-9]|AKIA|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|token=|password" README.md AGENTS.md docs modules plans specs
```

Expected: no matches except intentional placeholder or documentation text that does not contain a live value.

- [ ] **Step 6: Commit documentation content**

```bash
git add README.md modules/oidc-provider/README.md docs/getting-started.md docs/architecture.md docs/verification.md
git commit -S -m "docs: describe deployed AWS infrastructure"
```

### Task 3: Adapt Terraform Documentation Automation

**Files:**
- Create or modify: `.github/workflows/terraform-docs.yml`

**Interfaces:**
- Consumes `README.md` markers and `modules/oidc-provider/README.md` markers.
- Produces generated module documentation and redacted AWS-derived README sections.

- [ ] **Step 1: Adapt the canonical workflow path**

Use the raw canonical workflow as the starting pattern. Set `find-dir` to `modules/`, assemble `modules/*/README.md`, and preserve the inline Python replacement technique. Do not add a separate Python or shell script.

- [ ] **Step 2: Add safe AWS discovery**

Use read-only AWS CLI calls in workflow steps for STS, S3, IAM, Budgets, and Cost Explorer. Pipe JSON through inline processing and replace account IDs, ARNs, resource IDs, and state bucket names with placeholders before inserting Markdown.

- [ ] **Step 3: Add AUD Cost Explorer output**

Query current-month Cost Explorer actual and forecast values, multiply USD values by `1.55`, and write both source and converted values into the cost marker. State that the estimate is account-level and omit generated timestamps.

- [ ] **Step 4: Configure workflow triggers and permissions**

Retain pull-request documentation updates and add the post-merge `main` path required to refresh generated docs. Use least-privilege contents permissions plus OIDC read-only access for AWS queries. Preserve signed commits and avoid running a bot loop.

- [ ] **Step 5: Validate workflow syntax and marker behavior**

Run:

```bash
python3 - <<'PY'
import yaml
from pathlib import Path
yaml.safe_load(Path('.github/workflows/terraform-docs.yml').read_text())
print('workflow YAML parsed')
PY
```

Expected: `workflow YAML parsed`. Also run the workflow's inline marker logic locally with a temporary copy and verify it replaces only marked sections.

- [ ] **Step 6: Commit workflow changes**

```bash
git add .github/workflows/terraform-docs.yml
git commit -S -m "ci: automate safe Terraform documentation updates"
```

### Task 4: Verify Terraform and Documentation Sources

**Files:**
- Modify: `README.md` only if verification reveals an incorrect claim.
- Modify: `docs/verification.md` only if verification reveals an incorrect claim.

**Interfaces:**
- Consumes all prior documentation and workflow changes.
- Produces the final verified tool/source list.

- [ ] **Step 1: Validate Terraform Best Practices guidance**

Use the Terraform Best Practices MCP endpoint at `https://www.terraform-best-practices.com/~gitbook/mcp` to check the module README structure, provider constraints, backend documentation, and workflow practices. Record only the checks actually performed.

- [ ] **Step 2: Validate Terraform configurations**

Run:

```bash
terraform fmt -check -recursive
terraform -chdir=modules/oidc-provider init -backend=false
terraform -chdir=modules/oidc-provider validate
terraform -chdir=environments/test init -backend=false
terraform -chdir=environments/test validate
```

Expected: formatting passes and both configurations validate successfully.

- [ ] **Step 3: Run repository quality checks**

Run:

```bash
tflint --recursive --format compact
checkov -d . --quiet
```

Expected: no newly introduced failures. If a tool is unavailable, report that fact rather than claiming it was used.

- [ ] **Step 4: Verify safe AWS API facts**

Use AWS MCP if available, otherwise AWS CLI, to confirm the resource categories and Cost Explorer values used by the README. Redact all account IDs, ARNs, bucket names, and resource IDs in captured output and documentation.

- [ ] **Step 5: Update the verification section**

List Terraform Registry, Terraform Best Practices MCP, Terraform validation, TFLint, Checkov, and only the AWS CLI/MCP tools actually used. Do not list unavailable or unused tools.

- [ ] **Step 6: Run final secret-safety and diff checks**

Run:

```bash
rg -n "<aws-account-id>|arn:aws:|terraform-state-[0-9]|AKIA|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|token=|password" README.md AGENTS.md docs modules plans specs .github
git diff --check
git status --short
```

Expected: no live sensitive values, no whitespace errors, and only intended files modified.

### Task 5: Push and Open the Pull Request

**Files:**
- No additional files.

**Interfaces:**
- Consumes the verified commits on `docs/aws-documentation-refresh`.
- Produces a pushed branch and GitHub pull request targeting `main`.

- [ ] **Step 1: Verify signing configuration**

Run:

```bash
git config user.email
git config gpg.format
git config user.signingkey
```

Expected: the configured project signing email, `ssh`, and `~/.ssh/agent-gh-signing.pub`. Correct them before committing if they do not match the repository instructions.

- [ ] **Step 2: Rebase onto the target branch**

```bash
git fetch origin main
git rebase origin/main
```

Resolve conflicts without discarding unrelated user changes, then rerun the verification checks.

- [ ] **Step 3: Push the branch**

```bash
git push -u origin docs/aws-documentation-refresh
```

- [ ] **Step 4: Open the pull request**

```bash
gh pr create --base main --head docs/aws-documentation-refresh --title "docs: document deployed AWS infrastructure" --body-file /tmp/aws-documentation-pr.md
```

The PR body must summarize the README sections, module docs, workflow adaptation, redaction policy, Cost Explorer/AUD assumption, and verification results without including sensitive values.
