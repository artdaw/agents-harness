# AGENTS.md

**Engineering rules for AI coding agents. Without vibes, hallucinations, or scope creep.**

> Work it harder. Make it better. Make it faster. Make it stronger.
>
> But first, make sure it actually works.

Small diffs. Real tests. Honest reports.
A little paranoia is a feature, not a bug.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![AI Agents](https://img.shields.io/badge/AI-Agents-purple.svg)](#)
[![Engineering](https://img.shields.io/badge/Engineering-First-green.svg)](#)

---

## What Is This?

A practical engineering framework for AI-assisted software development.

Not another collection of magic prompts. Not a 400-page manifesto about the future of work. And definitely not an invitation for an LLM to rewrite half the codebase because it spotted an opportunity for "improvement".

This repository contains a modular set of rules, workflows, and tools designed to make AI coding agents more predictable, productive, and accountable.

The central idea:

**AI agents should operate like engineers, not enthusiastic autocomplete with root access.**

The system focuses on:

- **Context engineering** — retrieve relevant knowledge instead of flooding the model with everything.
- **Agentic workflows** — delegate work with explicit scope, boundaries, and recovery paths.
- **Verification-first development** — code is a hypothesis until tested.
- **Root-cause debugging** — reproduce, investigate, fix, verify.
- **Spec-driven development** — establish expected behavior before implementing complex changes.
- **Security and reliability** — treat input boundaries, secrets, permissions, and failure modes seriously.
- **Tool efficiency** — use existing tools, standard interfaces, and composable workflows.
- **Persistent knowledge** — preserve architectural context across sessions and agents.

The objective is simple:

Make AI-assisted development more predictable, reproducible, maintainable, and measurable.

## Engineering Philosophy

### 1. Context Is an Engineering Resource

More context does not automatically mean better reasoning.

Load relevant documentation, inspect the actual codebase, retrieve architectural knowledge, and avoid wasting tokens on unrelated information.

Context should be curated, not dumped.

### 2. Autonomy Needs Boundaries

An autonomous agent without constraints is just a very fast source of technical debt.

Define:

- Task scope.
- Allowed changes.
- Existing behavior that must be preserved.
- Verification requirements.
- Recovery strategy.

Give agents enough freedom to solve problems, not enough freedom to invent new ones.

### 3. Verification Beats Confidence

A successful command is not necessarily proof of correctness.

- Tests should validate behavior.
- Builds should use the actual project configuration.
- Security assumptions should be checked.
- Failure paths should be considered.
- Unverified claims should never be presented as facts.

"Works on my reasoning" is not an acceptable test result.

### 4. Root Causes Over Band-Aids

Reproduce first. Trace the execution path. Identify the actual cause.

Don't suppress errors, weaken tests, add arbitrary retries, or introduce fallback behavior just to make a failing check disappear.

### 5. Prefer Composable Tools

Use standard CLI workflows, MCP integrations, existing packages, and native platform capabilities.

Avoid reinventing functionality that already exists.

Custom code is justified when existing solutions don't fit — not because writing another implementation feels productive.

### 6. Humans Own the Decisions

Agents can investigate, implement, test, review, and propose architecture.

But responsibility for correctness, security, and architectural decisions must remain explicit.

The human is still the engineer. The model is a very capable, occasionally overconfident collaborator.

---

## Repository Structure

The repository is organized into a small core and supporting modules loaded only when needed.

| Path                         | Responsibility                                                                                                   |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `AGENTS.md`                  | Core rules, always loaded: mission, scope, decisions, customer mode, search, testing, recovery, skills, report. |
| `skills/harness-git/`        | Branch safety, diff checks, staging, commit message format, and the `commit-msg` hook.                          |
| `skills/harness-debug/`      | Root-cause debugging. Reproduce first. Do not mask errors or weaken tests.                                      |
| `skills/harness-testing/`    | Behavior tests, mocks, test data, flaky tests, and test commands by stack.                                      |
| `skills/harness-deps/`       | Dependency checks and package commands before you add or upgrade a package.                                     |
| `skills/harness-security/`   | Input boundaries, injection defense, secrets, auth, and network rules.                                          |
| `skills/harness-refactor/`   | Structure changes without behavior changes.                                                                     |
| `skills/harness-sdd/`        | Spec-driven flow for features, APIs, schemas, and architecture changes.                                         |
| `skills/harness-review/`     | Check before the final report: scope, leftovers, correctness, and honesty.                                      |
| `stacks/`                    | Per-stack sections. `project-init` copies them into a project `AGENTS.md` or `ENGAGEMENT.md`.                   |
| `bin/project-init.fish`      | Sets up a project: own project (Git, `.gitignore`, `AGENTS.md`) or customer project (`--client`).               |
| `evals/evals.md`             | Test scenarios and scoring for rule changes.                                                                    |

Skills use the `SKILL.md` format, so Claude Code and OpenCode load each one only when the task matches its description.
The `harness-` prefix prevents name conflicts with other installed skills.

### Stack-specific rules

- `stacks/docker.md`
- `stacks/go.md`
- `stacks/java.md`
- `stacks/node.md`
- `stacks/python.md`
- `stacks/sql.md`
- `stacks/terraform.md`
- `stacks/web.md`

The core document defines the rules. Skills and stack files provide the details.

No need to load the entire rulebook to fix a typo. We have better things to do.

---

## Toolchain

This setup uses a combination of AI tooling, CLI utilities, language toolchains, and persistent codebase context.

Some tools are essential to the workflow; others are optional accelerators.

### AI and Agent Infrastructure

| Tool                                                                   | Purpose                                                                                      |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| [Claude Code](https://code.claude.com/docs)                            | AI coding environment for Claude models.                                                     |
| [OpenCode](https://opencode.ai/)                                       | AI coding environment for Claude and OpenAI models.                                          |
| [MCP](https://modelcontextprotocol.io/)                                | Standardized interface for connecting models to external tools and contextual resources.     |


### Developer Tooling

| Tool                                             | Purpose                                                                |
| ------------------------------------------------ | ---------------------------------------------------------------------- |
| [fff](https://github.com/magnusmalm/fff-cli)     | Fast file discovery and content search.                                |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Precise source-code search and reference discovery.                    |
| [RTK](https://github.com/rtk-ai/rtk)             | Compresses command output to reduce noise and LLM context consumption. |
| [Git](https://git-scm.com/)                      | Version control, diff inspection, change isolation, and recovery.      |

### Language Toolchains

| Tool                              | Purpose                                                                                           |
| --------------------------------- | ------------------------------------------------------------------------------------------------- |
| [Go](https://go.dev/)             | Compiled systems software, CLI utilities, concurrency, testing, and performance-oriented tooling. |
| [Python](https://www.python.org/) | AI/ML development, automation, prototyping, and backend tooling.                                  |
| [uv](https://docs.astral.sh/uv/)  | Python environments, dependency management, and project execution.                                |
| [Node.js](https://nodejs.org/)    | JavaScript and TypeScript runtime and development ecosystem.                                      |
| [pnpm](https://pnpm.io/)          | Fast package management, reproducible installs, workspaces, and monorepo workflows.               |

### Why These Tools?

**fff + ripgrep**

Fast discovery and precise search.

Use specialized search tools when available, but never let a missing utility block progress. Standard shell tools are perfectly acceptable.

**RTK**

Terminal output consumes context.

Reducing noise means more room for actual reasoning, relevant source code, and test results.

**Go**

Prefer the standard toolchain before adding dependencies:

- `go build ./...`
- `go test ./...`
- `go test -race ./...`
- `go vet ./...`
- `gofmt -d .`

**Python + uv**

Keep environments reproducible and dependency management explicit.

Prefer `uv run`, `uv sync`, and the project's existing configuration over ad hoc global installations.

**Node.js + pnpm**

Use the package manager declared by the project.

- `pnpm install --frozen-lockfile`
- `pnpm run <script>`
- `pnpm exec <command>`
- `pnpm -r run <script>`

Preserve `pnpm-lock.yaml`. Don't silently switch to npm or Yarn.

---

## Search Strategy

The preferred search workflow:

1. `fff` — discover relevant files and content.
2. `rg` — verify exact definitions, references, and call sites.

Use the available tools intelligently.

If a preferred tool is missing, use a sensible alternative. Don't spend half the task installing a search utility just to avoid typing `rg`.

---

## Runtime Environment

This repository reflects an actual working environment rather than an imaginary universal developer workstation.

### Primary Environment

| Component               | Configuration |
| ----------------------- | ------------- |
| OS                      | macOS         |
| Shell                   | fish          |
| Terminal                | Standard      |
| Editor                  | VS Code       |
| Python                  | uv            |
| Node.js package manager | pnpm          |
| Systems language        | Go            |
| AI coding runtime       | Claude Code, OpenCode |
| Context integration     | MCP           |
| Version control         | Git           |

### Install

The rules use one fixed path, so both runtimes read the same files:

```fish
ln -s ~/Claude_Cowork/agents-harness ~/.config/agents-harness
```

Claude Code: add this line to `~/.claude/CLAUDE.md`:

```
@~/.config/agents-harness/AGENTS.md
```

OpenCode: link the global rules file:

```fish
ln -s ~/.config/agents-harness/AGENTS.md ~/.config/opencode/AGENTS.md
```

Skills: link each skill into both runtimes. Run this again after you add a skill:

```fish
for s in ~/.config/agents-harness/skills/*
    ln -sfn $s ~/.claude/skills/
    ln -sfn $s ~/.config/opencode/skills/
end
```

`project-init` on your PATH:

```fish
ln -s ~/.config/agents-harness/bin/project-init.fish ~/.local/bin/project-init
```

Do not put the rule files in `~/.config/opencode/agents/`. OpenCode reads that directory as agent definitions.

One source of truth for engineering rules is preferable to five subtly incompatible copies.

### Models

| Runtime     | Claude models | OpenAI models |
| ----------- | ------------- | ------------- |
| Claude Code | Yes           | No            |
| OpenCode    | Yes           | Yes           |

The rules do not depend on a model. In customer mode, `ENGAGEMENT.md` lists the allowed providers.
If a customer allows only OpenAI, use OpenCode.

---

## Customer Mode

For work in a customer repository (forward deployment, consulting):

```fish
project-init --client "Acme" --provider anthropic,openai
```

The script:

- Creates `ENGAGEMENT.md`: goal, allowed model providers, data rules, environments, and customer conventions.
- Excludes it in `.git/info/exclude`. The file stays on your machine. It is not committed.
- Adds the detected stack sections to `ENGAGEMENT.md`.
- Does not run `git init` and does not change the customer `.gitignore` or `AGENTS.md`.

When `ENGAGEMENT.md` exists, the agent follows the "Customer mode" section in `AGENTS.md`:

- It stops if its model provider is not allowed.
- It does not send customer code or data to services that are not allowed.
- It changes only the allowed environments.
- It follows the customer conventions instead of the defaults in `stacks/` and the `harness-git` skill.

---

## How to Use

1. Install the harness (see Install).
2. In each project, run `project-init`. Add `--client` for a customer repository.
3. Fill in the placeholders that the script reports.
4. Check the stack sections against the actual project.
5. Run a small task and inspect agent behavior.
6. Adjust rules based on observed failures, not theoretical preferences.

The system should evolve with the codebase and the tools.

Don't add rules just because they sound smart. Add them because they prevent a real class of mistakes.

---

## Evaluation and Continuous Improvement

Instructions are software too.

They can become outdated, contradictory, overly restrictive, or simply ineffective.

Use `evals/evals.md` to evaluate changes to the agent rules.

Useful evaluation scenarios include:

- Does the agent inspect existing changes before editing?
- Does it preserve unrelated user modifications?
- Does it reproduce bugs before attempting fixes?
- Does it avoid unnecessary dependencies?
- Does it select the correct package manager?
- Does it run meaningful tests?
- Does it report skipped checks honestly?
- Does it avoid expanding task scope?
- Does it recover safely from failed operations?

A rule that looks good in Markdown but changes no agent behavior is just documentation decoration.

---

## Reporting Format

Every completed task should produce a concise, evidence-based report.

The standard structure:

| Section      | Meaning                             |
| ------------ | ----------------------------------- |
| STATUS       | Current verified state.             |
| ACTION       | What was done or what must be done. |
| RESULT       | Observed outcome.                   |
| VERIFICATION | Evidence and checks performed.      |
| RISK         | Remaining risks or limitations.     |
| NEXT ACTION  | Required follow-up, if any.         |

At the end, include a **Decisions** list documenting important implementation choices and their rationale.

No hiding failed tests. No pretending skipped checks passed. No "everything looks good" when nothing was actually verified.

---

## Design Principles

- Small changes are easier to review.
- Explicit assumptions are easier to challenge.
- Reproducible workflows are easier to trust.
- Modular instructions are easier to maintain.
- Good defaults reduce unnecessary decisions.
- Real verification beats confident language.
- Engineering discipline matters more than model enthusiasm.

And one final rule:

**Never confuse generating code with solving a problem.**

The first is easy. The second is the job.

---

## Credits and License

Forked from [pavelveter/AGENTS.md](https://github.com/pavelveter/AGENTS.md). MIT.
