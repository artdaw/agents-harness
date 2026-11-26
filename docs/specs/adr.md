# ADR skill

## Goal

Agents record architecture decisions in the format of Michael Nygard, "Documenting Architecture Decisions" (2011), as close to the original as possible.

## Behavior

1. `harness-adr` loads on an explicit request for an ADR or for recording a decision. The load condition shares the `harness-prd` line in `AGENTS.md`.
2. `harness-sdd` also writes an ADR when its spec makes a decision that is hard to reverse. Spec and ADR link to each other.
3. Location: the project ADR folder if one exists, otherwise `docs/adr/`. File name: `NNNN-<short-kebab-title>.md`. Numbers are sequential and never reused.
4. Sections in Nygard order: Title, Context, Decision, Status, Consequences. Full sentences. One or two pages.
   Context describes the forces neutrally and names the alternatives considered. Decision uses "We will ...". Consequences list positive, negative, and neutral results.
5. Status values: `Proposed`, `Accepted`, `Deprecated`, `Superseded by ADR NNNN`. The agent writes `Proposed`. It sets `Accepted` or `Deprecated` only when a human says so.
6. An accepted ADR is never edited or deleted. A new ADR supersedes it. When the new ADR becomes `Accepted`, the same change sets the old Status line to `Superseded by ADR NNNN`. An agent that finds this step missed reports it, and fixes the Status line when the task allows changes in the ADR folder.
7. The ADR records the decision. It does not implement it.

## Acceptance criteria

- `AGENTS.md` stays at 199 lines and names `harness-adr`.
- `bin/install.sh` links the skill with its template for both runtimes.
- `evals/evals.md` has scenarios 49 to 53, including a feature that needs no ADR and the supersede step.

## Assumptions

- The user wrote "Docs/ads". This spec reads it as `docs/adr/`.
- No "Options considered" section: Nygard puts the alternatives in Context. MADR adds that section; this skill does not.
- No date field: Nygard has none, and Git records the date.
- "Supersedes ADR NNNN" goes on the Status line, as `adr-tools` does. Nygard does not say where it goes.
- File names use `NNNN-title.md` (as `adr-tools` does) instead of Nygard's `adr-NNN.md`, because the title makes the folder readable. A project with another scheme keeps its scheme.
