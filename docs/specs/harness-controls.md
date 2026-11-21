# Harness controls: contract, state, verifier, deny list, loops, graphs, lessons

## Source

The article "Agent = Model + Harness" (user-provided text, November 2026).
Its claim: the system around the model changes results more than the prompt does.
Its checklist has ten questions. This spec maps each one to the harness.

## Gap analysis

| Article question | Harness before this change | Result |
| --- | --- | --- |
| Is "done" defined before it starts? | "Read the task fully". Acceptance criteria only in `harness-sdd`. | Gap. Add a task contract. |
| Can it find context without loading everything? | Short core file. Skills load on demand. Project index of technology skills. | Covered. |
| Does every tool have a clear purpose and failure message? | Not in scope. The harness does not define tools. | No change. |
| Are decisions stored outside the chat? | DECISIONS exist only in the final report. | Gap. Add a state file. |
| Does completion require evidence? | VERIFICATION lists commands with exit codes. | Covered. |
| Is the checking done by something other than the builder? | `harness-review` is a self-review. | Gap. Add an independent verifier. |
| Are risky actions blocked by policy, not by a sentence? | `AGENTS.md` says "Dangerous commands are blocked by config". The repository ships no config. | Gap. Ship a deny list. |
| Does every loop have a retry cap and a budget? | 3 attempts per problem. No stop check, budget, or failure classes for repeating or unattended runs. | Gap. Add `harness-loop`. |
| Do several agents coordinate? (article: graph layer) | No rules. The harness assumes one agent. | Gap. Add `harness-graph`. |
| Can the run resume after a crash? | No. | Gap. The state file covers it. |
| Does each failure leave a rule, a test, or a check behind? | "Add a rule only when it prevents a mistake that you saw." No path from a rule to a check. | Gap. Add the enforcement ladder to the README. |

## Behavior

1. Task contract. Before the first edit, the agent writes: goal, constraints, done when, if blocked.
   "Done when" lists the commands or observations that prove the result.
   A simple question needs no contract.
2. State file. A task with more than one step, or that can outlive the session, keeps `.agent/STATE.md`.
   It holds the contract, current step, decisions, artifacts, open risks, and next action.
   The agent reads it first if it exists. The agent updates it after each step and before it stops.
   The file is not committed. The agent excludes `.agent/` in `.git/info/exclude` if Git does not ignore it.
3. Independent verifier. `harness-review` runs `verifier.md` in a fresh subagent for each behavior change.
   The verifier tries to reject. It replies with one `REJECT:` or one `ACCEPT:` line per criterion.
   A rejection is a failed attempt and counts toward the limit of 3.
   If the runtime has no subagents, the agent runs the verifier as a separate pass and writes this in the report.
4. Enforced deny list. `config/claude-settings.json` denies commands that the rules already forbid.
   `bin/install.sh` copies it to `~/.claude/settings.json` only if that file does not exist.
   Otherwise it prints a warning to merge the rules by hand.
   A deny rule matches the start of a command only. It stops mistakes, not an attacker.

5. Loops (`harness-loop`). Repeating or unattended work needs a loop contract in the state file before the first iteration:
   trigger, scope, stop check (a command), budget, escalation. No stop check or no budget: no loop.
   Each failure is classified. A pending result uses the time budget, not the attempt limit. The same error twice with no change stops the loop.
6. Graphs (`harness-graph`). More than one agent needs a graph design in the state file:
   one orchestrator, workers with disjoint file ownership and one worktree per writer, a separate verifier.
   Workers do not start agents, talk to each other, merge, or push. The orchestrator merges one result at a time with checks, only if the task allows merges.
   Otherwise it reports the worker branches. The `harness-review` verifier alone does not load this skill.

7. Lessons (`harness-lessons`). The final report has a LESSONS list with proposed rules. The agent changes the rules only when a human asks.
   A first incident becomes a rule or checklist line. A repeated mistake moves one level down: rule, checklist line, automated check, deny rule. Each rule traces to an incident.
   Only the task prompt, or a triggering review comment from a person with write access, can ask for a lesson.
   Prune mode removes a rule only with eval results on each model. A human decides.

## Acceptance criteria

- `AGENTS.md` stays under 200 lines.
- `bin/install.sh` on an empty `HOME` creates `~/.claude/settings.json` equal to `config/claude-settings.json`.
  A second run exits 0, prints no settings warning, and does not change the file.
- `bin/install.sh` with a different `~/.claude/settings.json` does not change it and prints a warning.
- The deny list contains only commands that existing rules forbid. Read-only commands such as `terraform state list` stay allowed.
- `config/claude-settings.json` is valid JSON.
- `evals/evals.md` has a scenario for each new behavior, including loops (25 to 27) and graphs (28, 29).
- `AGENTS.md` names `harness-loop`, `harness-graph`, and `harness-lessons` with a load condition.
- The final report format has a LESSONS list. Evals 30 to 34 cover lessons, pruning, and untrusted requests.

## Assumptions

- The article does not name its author's runtime config. Deny rules use the Claude Code `permissions.deny` format.
- No OpenCode permission file. The OpenCode documentation was not reachable, so the format is not verified.
- No change to `project-init`. The agent excludes `.agent/` itself. This keeps both scripts unchanged.
- The core retry rule stays. `harness-loop` adds the loop-level rules: stop check, budget, failure classes.
- Loops and graphs are skills, not core rules. Most tasks use one agent once. The skills load only when the condition is true.
- The contract lives in the state file or in the first message. No separate contract file.
