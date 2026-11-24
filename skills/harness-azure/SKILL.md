---
name: harness-azure
description: Use when you work with Azure resources or the az CLI, Terraform azurerm or azuread, AKS, Azure Database for PostgreSQL, Key Vault, Service Bus, Entra ID, or Azure SDK clients in code.
---

# Azure

## Before any az command
- Run `az account show`. Check the tenant and the subscription. Pass `--subscription` on each command. Do not change the default subscription.
- Use read-only commands (`show`, `list`) unless the task allows a change in that environment.
- Resources that Terraform manages change only through Terraform. An `az` change creates drift. Follow `stacks/terraform.md`: plan only.
- Do not change a SKU, a region, or a replica count without approval. These change cost and availability.

## Identity (Entra ID)
- Code authenticates with `DefaultAzureCredential` or the managed identity. No client secret or connection string with a key in code or config.
- Pods on AKS use workload identity: a federated credential on a user-assigned managed identity, and a service account annotation.
- Give each identity the smallest role at the smallest scope. Prefer a resource scope to a resource group or subscription scope.

## Key Vault
- Use the RBAC permission model. The app reads secrets at runtime: the Azure SDK, or the Secrets Store CSI driver on AKS.
- Never print a secret value. `az keyvault secret show` prints it. Use `--query id` or `list` to check that a secret exists.
- Keep soft delete and purge protection on. Never purge a secret or a vault.

## AKS
- `az aks get-credentials` changes the current kubeconfig context. Run `kubectl config current-context` before each `kubectl` command.
- Node pools, versions, and add-ons change through Terraform. Follow `harness-kubernetes` for workloads.

## Azure Database for PostgreSQL (Flexible Server)
- Connect with Entra ID authentication or a password from Key Vault. TLS is required.
- `max_connections` depends on the SKU. Use a pool, or the built-in PgBouncer.
- Server parameters change through Terraform. A point-in-time restore creates a new server; it does not overwrite the old one.
- Follow `harness-postgres` and `stacks/sql.md` for schema and queries.

## Service Bus
- Delivery is at least once. Handlers are idempotent.
- Use peek-lock. Complete the message after the work succeeds. Abandon or dead-letter it on failure.
- Watch the dead-letter queue. Set `max_delivery_count` on purpose. Use sessions when the order matters.
- Message size limits depend on the tier. Large payloads go to storage, and the message holds a reference.

## Terraform (azurerm, azuread)
- Pin the provider versions. Keep the remote state in a storage account with locking.
- Add `lifecycle { prevent_destroy = true }` to stateful resources: database servers, Key Vaults, Service Bus namespaces, storage accounts.
- If a plan replaces or destroys a stateful resource, stop and report it.
