---
name: harness-loop
description: Use when work repeats without a human prompt for each step: /loop or the runtime equivalent, a scheduled task, a retry loop, a "keep going until it passes" run, or a script that prompts an agent. Defines the trigger, stop check, budget, and escalation.
---

# Loops

A loop prompts, acts, checks, and decides. The check decides when to stop. The model does not.

## Before the first iteration
Write a loop contract in `.agent/STATE.md`:
- Trigger: what starts each iteration (schedule, event, previous iteration).
- Scope: what one iteration may change. Keep it to one bounded step.
- Stop check: a command that returns exit code 0 when the work is done. Not a model opinion.
- Pending output: what the stop check shows while the work is still running (deploy in progress, CI queued), if this can occur.
- Budget: maximum iterations, wall-clock time, and spend. Default: 3 attempts per problem.
  Time has no default. The contract must state it.
- Escalation: who gets the report, and where.
No stop check or no budget: do not start the loop. Report what is missing.

## Each iteration
1. Read `.agent/STATE.md`. Do not rely on earlier conversation.
2. Do one step. The step must be safe to run twice with the same result.
3. Run the stop check. Record the command, the exit code, and the error text.
4. Update `.agent/STATE.md`: step, result, attempts used, budget left, next action.

## Classify each failure
- Timeout or network error: retry one time after a pause.
- Bad tool arguments: fix the call.
- Missing information: get it from an allowed source, or stop and report it. In customer mode, `ENGAGEMENT.md` limits the sources.
- Test failure: read the failing behavior. Change the code, never the test.
- Permission denied: stop. Report it. Do not look for a bypass.
- Pending output: not a failure. Wait for the next trigger. It uses the time budget, not the attempt limit.
- Same error as the previous iteration, and nothing changed: stop. Do not retry.
- Edits to the same lines in 3 iterations: stop. The plan is wrong, and the loop cannot see the plan.

## Stop
Stop when the stop check passes, the budget ends, or a stop rule above applies.
Then write the final report. On failure, list each attempt and its error.
A loop that ends without a passing stop check never reports "done".
