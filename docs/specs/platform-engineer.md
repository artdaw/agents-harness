# Platform engineer: SRE skill, four technology skills, and an agent definition

## Goal

Agents that work on the platform stack follow the same judgment as a senior platform engineer:
backend (Python with FastAPI, Kotlin with Spring Boot, TypeScript), SRE, and DevOps
on Azure (AKS, Azure Database for PostgreSQL, Key Vault, Service Bus, Entra ID), Terraform, Redis, Temporal, Docker, Kubernetes,
Grafana LGTM (Loki, Grafana, Tempo, Mimir) with Alloy, and Datadog.

## Design

One persona skill would load every rule on every task. The harness loads knowledge per technology instead.

| Part | Type | Loads when |
| --- | --- | --- |
| `harness-sre` | Process skill | Infrastructure, deploy, alerting, capacity, or incident work |
| `harness-fastapi` | Technology skill | `fastapi` in a Python manifest |
| `harness-kotlin` | Technology skill | The Kotlin Gradle or Maven plugin |
| `harness-azure` | Technology skill | Azure SDKs, `azurerm` in Terraform files, or `az` work |
| `harness-grafana` | Technology skill | Grafana, Prometheus, Loki, or Mimir in manifests or Compose; Alloy or Prometheus config files |
| `platform-engineer` agent | Agent definition | A person or an orchestrator starts it by name |

Existing skills stay as they are: `harness-postgres`, `harness-temporal`, `harness-redis`, `harness-kubernetes`, `harness-datadog`, `harness-typescript`.

## Behavior

1. `harness-sre` defines the production change procedure (read-only first, blast radius, rollout, rollback, observability, capacity),
   a reliability checklist for services, and an incident procedure (read-only diagnosis, evidence, mitigation proposed to a human, lessons).
2. Each technology skill holds rules for one technology. It tells the agent to check the installed version first.
3. `project-init` detects the new technologies and writes their load lines.
   It also reads `*.tf` files, so `azurerm` resources select the Azure, PostgreSQL, and Redis skills.
4. The agent definition is a thin role. It points to `AGENTS.md`, `harness-sre`, and the technology skills. It does not repeat their rules.
   Claude Code: `agents/claude/platform-engineer.md`. OpenCode 1.x: `agents/opencode/platform-engineer.md`. `install.sh` links both.
5. The Claude Code deny list adds `ask` rules for `helm install`, `helm upgrade`, `helm uninstall`, and `helm rollback`,
   and `deny` rules for `az group delete`, `az keyvault purge`, `az aks delete`, `az postgres flexible-server delete`, and `az servicebus namespace delete`.

## Acceptance criteria

- `AGENTS.md` stays under 200 lines. It names `harness-sre` with a load condition and lists the four technology skills.
- `project-init` (bash) detects FastAPI, Kotlin, Azure, and Grafana on sample projects, and selects nothing extra on a project without them.
- `install.sh` on an empty `HOME` links the agent file for both runtimes.
- The two agent files have the same body.
- `config/claude-settings.json` is valid JSON.
- `evals/evals.md` has scenarios for the SRE skill and for each technology skill.

## Assumptions

- Agent frontmatter: Claude Code uses `name`, `description`, `tools`. OpenCode 1.19.6 uses `description`, `mode`, `permission` (from the binary schema; `tools` is deprecated there). Two files, because the formats differ.
- The OpenCode agent gets no `bash` permission patterns. The match order of patterns is not verified. The guard plugin and the rules still apply.
- Kotlin and Spring Boot share one skill, because the stack uses Spring Boot with Kotlin only.
- The `tempo` word is not a detection pattern. It matches `temporal`.
- Grafana and Datadog both exist in the stack. The skills do not choose the alert source of truth. The project `AGENTS.md` must name it.
