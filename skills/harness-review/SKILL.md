---
name: harness-review
description: Use before the final report of any task that changed files. Checks scope, leftovers, correctness, and report honesty, then runs an independent verifier.
---

# Review before the final report

Run `git diff` and `git status`. Read the full diff. Answer each question.

## Scope
- Does every changed file belong to the task?
- Is there any formatting, rename, or cleanup that the task did not need? Remove it.
- Did you touch existing user changes? If yes, restore them.

## Leftovers
- Debug output: `print`, `console.log`, `fmt.Println`, `dbg!`.
- Commented-out code.
- `TODO` or `FIXME` that you added.
- Temporary files, logs, `.agent/` files in the diff.
- Secrets, tokens, local paths, or user names.

## Correctness
- Does the diff match what you will write in the report?
- Does each behavior change have a check that fails if the logic breaks?
- Did you handle errors and resource cleanup in the new code?
- Did you run the checks of every stack that you changed? Did each command return exit code 0?

## Report
- VERIFICATION lists only commands that you ran in this session.
- Each assumption and decision is in the DECISIONS list.
- Each failed or skipped check is in the report with the reason.
- Each mistake that you, a check, or the verifier caught, and that a rule or check could prevent, is in LESSONS with a proposed rule and level.

If any answer is wrong, fix it. Then run this list again.

## Independent verifier
Skip this step for a change of 5 lines or fewer that does not change behavior, and for a change to documentation only.

1. Start a fresh subagent with the brief in `verifier.md` in this skill directory.
   Give it only the task contract, `git diff`, `git status`, and the check output with exit codes.
2. `ACCEPT`: add `verifier: ACCEPT` to VERIFICATION, with each command that the verifier ran and its exit code.
3. `REJECT`: this is a failed attempt. Fix the cause. Run the checks and the verifier again.
   Follow the Failure recovery limit of 3 attempts.
4. If the runtime cannot start a subagent, do the verifier checks yourself in a separate pass.
   Write "verifier: same session" in the report.