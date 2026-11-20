## Stack: Terraform or OpenTofu
Applies to the directory that contains `*.tf` files.
Use `tofu` instead of `terraform` if the project uses OpenTofu (`.opentofu-version`, or `tofu` in CI or docs).
- Never run `apply`, `destroy`, `import`, `state rm`, `state mv`, `state push`, or `force-unlock`.
  Write the command in the report for a human to run.
- Run `plan` only for an environment that the task allows. Write the plan summary in the report: add, change, destroy.
  If the plan destroys or replaces a resource, stop and report it.
- Do not change the backend configuration.
- Checks without a backend: `terraform init -backend=false`, then `terraform fmt -check -recursive` and `terraform validate`.
- Lint: `tflint --recursive` if `.tflint.hcl` exists.
- Security scan: `trivy config .` or `checkov -d .`. Use the tool that the project uses.
- Test: `terraform test` if `*.tftest.hcl` files exist.
- Pin `required_version` and each provider in `required_providers`. Commit `.terraform.lock.hcl`.
  Run `terraform init -upgrade` only when the task asks for an upgrade.
- Never put secrets in `.tf` or `.tfvars` files. Mark secret variables and outputs `sensitive = true`.
  Never commit `*.tfstate` or plan files.
- Give each variable a `type` and a `description`. Add a `validation` block for inputs with a fixed format.
  Do not hardcode account IDs, regions, or environment names in modules.
- To rename or move a resource, use a `moved` block. Do not use state commands.
