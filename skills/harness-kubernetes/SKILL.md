---
name: harness-kubernetes
description: Use when you write or change Kubernetes manifests, Helm charts, or Kustomize overlays, or run kubectl or helm against a cluster.
---

# Kubernetes

## Cluster access
- Before each `kubectl` or `helm` command, check the context: `kubectl config current-context`.
  Pass `--context` and `--namespace` explicitly.
- On a cluster that you are not allowed to change, run only read-only commands: `get`, `describe`, `logs`, `top`, `events`.
- Before a change, run `kubectl diff` or `--dry-run=server`. Write the apply command in the report for clusters you may not change.
- If the project uses GitOps (Argo CD, Flux), change the Git repository. Do not apply to the cluster by hand.
- Do not `exec` into a production pod or delete pods to "fix" a problem without approval.

## Manifests
- Check the cluster version and the API versions (`kubectl api-resources`). Do not use removed APIs.
- Pin images to a tag or a digest. Never use `latest`.
- Set resource requests and a memory limit. Follow the project policy for CPU limits.
- Add readiness and liveness probes. Add a startup probe for slow starts. A liveness probe must not depend on other services.
- Security context: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true` when possible, drop `ALL` capabilities.
- Graceful shutdown: the app handles `SIGTERM`. Set `terminationGracePeriodSeconds` above the drain time.
- More than one replica: add a `PodDisruptionBudget`.

## Secrets
- Never commit a plain `Secret` manifest. Base64 is not encryption.
- Use the secret tool of the project (External Secrets, Sealed Secrets, SOPS, or a cloud secret store).

## Checks
- Helm: `helm lint` and `helm template`. Use `helm diff` if the plugin is installed.
- Kustomize: `kubectl kustomize <dir>`.
- Validate rendered output with `kubeconform` if it is installed.
