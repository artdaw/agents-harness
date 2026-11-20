---
name: harness-datadog
description: Use when you add or change Datadog instrumentation (traces, metrics, logs), monitors, dashboards, or SLOs, or query Datadog data.
---

# Datadog

## Instrumentation
- Use the tracer that the project uses (`ddtrace`, `dd-trace` for Node, `dd-trace-go`, `dd-java-agent`) or OpenTelemetry. Do not add a second one.
- Set unified service tags: `DD_ENV`, `DD_SERVICE`, `DD_VERSION`. Do not hard-code them in code.
- Check `DD_SITE` (for example `datadoghq.eu`). It decides the data region.
- Do not change the trace sample rate or log volume without approval. Both change the cost.

## Metrics
- Follow the metric naming of the project: lowercase, dot-separated namespace, for example `checkout.payment.failed`.
- Custom metrics are billed per unique tag combination.
  Do not use high-cardinality tags: user ID, request ID, email, full URL. Put these in span attributes or logs.

## Logs
- Write structured JSON logs. Connect logs and traces (`DD_LOGS_INJECTION=true` or the tracer option).
- Never log secrets, tokens, or personal data. Datadog is an external service.
  In customer mode, send data only if `ENGAGEMENT.md` allows Datadog.

## Monitors, dashboards, SLOs
- If the project manages them as code (Terraform `datadog` provider, or JSON in the repository), change the code. Do not change them in the UI.
- Each monitor needs a clear message, the owner or team tag, and a runbook link if the project has runbooks.
- Use `terraform plan` to check a change. Do not apply to a shared account; write the command in the report.

## Keys
- The API key sends data. The application key reads and configures. Never put either in code, tests, or logs.
- Use read-only access to query data. Do not create or mute monitors on a shared account without approval.
