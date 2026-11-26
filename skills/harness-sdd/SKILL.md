---
name: harness-sdd
description: Use before you implement a new feature, public API, schema, persistence, or architecture change. Write the spec first.
---

# SDD

No user is available. Do not ask questions.

1. Search `docs/` and existing specs with `rg`. Do not duplicate a spec.
   If a PRD for the feature exists with `Status: accepted`, link to it, and map each requirement ID (`R1`, `N1`, ...) to an acceptance criterion.
   If the PRD has `Status: draft`, link and map it the same way, and write in DECISIONS that it is not accepted.
   A PRD is optional. Do not wait for one.
2. Write or update `docs/specs/<feature>.md` before you implement.
   Create `docs/specs/` only if needed.
   If the spec makes a decision that is hard to reverse (datastore, protocol, framework, service boundary, security model,
   or a dependency that many modules use),
   also write an ADR with `harness-adr`. Link the spec and the ADR to each other.
3. In the spec, add an "Assumptions" section.
   For each unclear decision, write the choice you made and the reason.
   Choose the option that is reversible and keeps existing behavior.
4. Define observable behavior and acceptance criteria.
   State what must be true. Do not add implementation detail.
5. Implement and test against the spec.
6. Update the spec to match the final behavior.
7. List the assumptions in the DECISIONS part of the final report.

New config values need: config, parse, validate, runtime use, observable behavior.
Each value needs a safe fallback and a short note: purpose, valid range, default.
Verify runtime behavior, not only parsing.