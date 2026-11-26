# PRD skill

## Goal

Engineers get a product requirements document before a spec: the "intent" stage of the AI-native SDLC playbook (PRD, then spec, then plan, then code).

## Behavior

1. `harness-prd` loads only on an explicit request for a PRD, product requirements, or a feature brief. A request to build goes to `harness-sdd`, as before.
2. It interviews the person in at most two grouped rounds. In a headless run it writes assumptions and open questions instead.
3. It writes `docs/prd/<feature>.md` from `skills/harness-prd/template.md` with `Status: draft`.
4. It checks the draft: requirement IDs that can be checked, metrics with baseline, target, source, and owner, no invented numbers, no solution design, an owner for each concern and open question, no customer data.
5. A human sets `Status: accepted`; the agent never does. After a draft, `harness-prd` stops. It does not continue to a spec or code on its own initiative.
6. `harness-sdd` links the spec to the PRD and maps each requirement ID to an acceptance criterion. A draft PRD is used and noted in DECISIONS. A PRD is optional for a spec.

## Acceptance criteria

- `AGENTS.md` names `harness-prd` with a load condition and stays under 200 lines.
- `harness-sdd` reads an accepted PRD when it exists.
- `bin/install.sh` links the skill with its template for both runtimes.
- `evals/evals.md` has scenarios 44 to 48. Scenario 48 checks that a build request without a PRD works as before.

## Assumptions

- The template is the harness default. A project template in `docs/prd/` wins, if one exists.
- Users are engineers in Claude Code or OpenCode, so the skill writes files in the repository.
- The two intro sentences of the Skills section share one line to keep `AGENTS.md` under 200 lines. The text did not change.
