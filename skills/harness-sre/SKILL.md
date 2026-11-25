---
name: harness-sre
description: Use for infrastructure, deploy, CI/CD, Kubernetes, Helm, Terraform, alerting, capacity, or production performance work, and for incidents. Production change procedure, service reliability checklist, and incident procedure.
---

# SRE

The agent prepares a production change. A human applies it. The agent may act up to the production gate and cannot pass it.

## Before a change that reaches an environment
1. Name the target before each command: Kubernetes context and namespace, Azure subscription, Terraform workspace.
2. Read the current state first, read-only: `kubectl get`, `az ... show`, `terraform plan`, the recent deploys, and the dashboards.
3. Write the blast radius: which services and users fail if the change is wrong.
4. Write the rollout: dev, then staging, then production. One change at a time.
   Use a canary, `maxUnavailable`, or a feature flag when the change can fail under load.
5. Write the rollback: the exact command or revert. A data or schema change uses expand and contract (`stacks/sql.md`).
6. Name the signals that prove success or failure: a metric, a log query, a trace. Add them if they do not exist.
7. Check capacity: CPU and memory requests and limits, HPA bounds, database connections
   (pool size x replicas x services must stay under `max_connections`), and queue throughput.
8. Put steps 3 to 7 in the report or in `.agent/STATE.md`. In environments that the task does not allow, follow the stack rules: plan and dry run only.

## Service reliability checklist
- Every network call has a timeout. Retry only idempotent calls, with backoff and jitter, and a limit.
- The service stops cleanly on `SIGTERM`: it stops accepting work and finishes in-flight work within `terminationGracePeriodSeconds`.
- Liveness checks only the process. Readiness checks the dependencies that the service needs to serve traffic. A slow start uses a startup probe.
- Message and workflow handlers are idempotent: Service Bus, Kafka, Temporal activities.
- Configuration comes from the environment or Key Vault. No secrets in images, manifests, or Helm values in Git.
- Each new endpoint or job has a latency and an error-rate signal.

## Incident
1. Diagnose read-only. Start from the symptom (SLO, error rate, latency), then check what changed: deploys, configuration, infrastructure, dependencies.
2. Record a timeline and the evidence in `.agent/STATE.md`: each query or command, and what it showed.
   Write a summary of the output, not raw customer data. In customer mode, redact customer data.
3. Propose a mitigation. Rollback of the last change is the default. A human authorizes each production action, unless a runbook pre-approves it.
4. After recovery, write the incident record in the final report: impact, cause, evidence, fix, and follow-ups.
   Write it to a file only if the project already has a place for incident records, or the task asks for one.
   Put the proposed eval scenario and rule in the LESSONS list of the final report.

## Do not
- Do not run a write command before you name its target.
- Do not change production by hand: no `kubectl edit`, `kubectl patch`, or portal changes outside the GitOps or Terraform flow.
- Do not silence, delete, or raise the threshold of an alert to make it pass.
- Do not add replicas, memory, or CPU as a fix before you know the cause. Write it as a mitigation with a follow-up.
