---
name: harness-temporal
description: Use when you write or change Temporal workflows, activities, workers, signals, queries, updates, or schedules, or run the temporal CLI.
---

# Temporal

Check the SDK and its version first (Go, Java, TypeScript, Python, .NET). Read the docs for that SDK.

## Workflow code must be deterministic
Workflow code replays from the event history. A replay must make the same commands in the same order.
- Do not read the wall clock, random numbers, environment, files, or network in workflow code.
  Use the SDK APIs: Go `workflow.Now`, `workflow.Sleep`; Java `Workflow.currentTimeMillis`, `Workflow.sleep`;
  Python `workflow.now()`, `workflow.random()`; TypeScript `sleep` from `@temporalio/workflow`.
- Go: do not use goroutines, channels, `select`, or map iteration order in workflows.
  Use `workflow.Go`, `workflow.Channel`, and `workflow.Selector`.
- Put all I/O and side effects in activities.
- Do not log with a normal logger in workflows. Use the workflow logger. It does not log again on replay.

## Changing workflow code
- Running executions replay the new code. A change in command order breaks them with a non-determinism error.
- Use the versioning API of the SDK for each such change:
  Go and Java `GetVersion`; TypeScript and Python `patched` and `deprecatePatch`.
  Or use Worker Versioning, if the project uses it.
- Run a replay test with saved histories after each workflow change. Use the SDK replayer.

## Activities
- Make each activity idempotent. It can run more than one time.
- Set `StartToCloseTimeout` on each activity. Set a retry policy. Mark errors that must not retry as non-retryable.
- Long activities: send heartbeats and set `HeartbeatTimeout`.

## History and payloads
- Keep payloads small. Pass IDs, not large documents.
- Use continue-as-new in long loops. The history has a hard limit (about 50,000 events or 50 MB).
- Do not put secrets in payloads. Payloads are stored in the history. Use the payload codec of the project for sensitive data.

## Tests
- Use the SDK test environment with time skipping. Mock activities in workflow tests.

## CLI
- Local server: `temporal server start-dev`.
- Read-only: `temporal workflow list`, `describe`, `show`.
- `terminate`, `cancel`, `reset`, `signal`, and batch operations change state.
  Run them only on an environment that you are allowed to change. For other environments, write the command in the report.
