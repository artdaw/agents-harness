---
name: harness-grafana
description: Use when you add or change metrics, logs, traces, dashboards, or alert rules for the Grafana stack (Loki, Grafana, Tempo, Mimir, Prometheus, Alloy), or write PromQL, LogQL, or TraceQL.
---

# Grafana stack (LGTM)

Loki stores logs, Tempo stores traces, Mimir stores metrics (Prometheus-compatible), and Grafana shows them.
Grafana Alloy collects telemetry. Do not add Grafana Agent or Promtail to new code: both are deprecated in favor of Alloy.
If the project also uses Datadog, the project `AGENTS.md` names the source of truth for alerts. If it does not, write the assumption in the report.

## Instrumentation
- Use OpenTelemetry SDKs or Micrometer, as the project does. Send OTLP to Alloy. Do not add a second instrumentation library.
- Every signal has `service.name`, `service.version`, and the environment.
- Propagate W3C `traceparent` across HTTP, Service Bus, and Temporal calls.

## Metrics
- Prometheus names: `snake_case`, base units, and a unit suffix (`_seconds`, `_bytes`). Counters end in `_total`.
- Never use a high-cardinality label: user ID, request ID, email, full URL, raw path. Use the route template.
- Use a histogram for latency. Use `rate()` or `increase()` on counters, never on gauges.

## Logs
- Write structured JSON logs. Include `trace_id` and `span_id`.
- Loki labels have low cardinality: service, environment, namespace, level. Other fields stay in the log line or in structured metadata.
- In LogQL, filter by labels first, then by line content.
- Never log secrets, tokens, or personal data.

## Traces
- Span names have low cardinality: `GET /orders/{id}`, not the full URL.
- Do not change the sampling rate without approval. It changes cost and coverage.

## Dashboards and alerts
- Dashboards and alert rules live in Git: provisioning files, Terraform, or JSON. Do not change them by hand in Grafana.
- Alert on symptoms (error rate, latency, saturation against an SLO), not on causes.
- Each alert has a `severity` label, a `for` duration, a `summary`, and a `runbook_url`.
- Check Prometheus rule files with `promtool check rules`, and run `promtool test rules` when tests exist.
