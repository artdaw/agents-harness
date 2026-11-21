---
name: harness-graph
description: Use when more than one agent changes files for the same task or repository: subagents that write, parallel sessions, work split across workers. Not for the harness-review verifier alone. Defines roles, file ownership, isolation, and how results are combined.
---

# Agent graphs

A graph is a set of agents and the edges between them: who gives work to whom, and who combines the results.
Design the graph before you start the agents. Write it in `.agent/STATE.md`.

## Roles
- Orchestrator: one per task. It splits the work, starts the workers, combines the results, and runs the final checks.
  It owns the task contract and the final report.
  The `harness-git` rules apply to the orchestrator and to each branch that a worker creates.
- Worker: gets one bounded contract (goal, constraints, done when, if blocked) and the files it owns.
  It returns a result and its check output. It does not start other agents.
- Verifier: did not build the change. It tries to reject it. Use `verifier.md` from `harness-review`.

## Split the work
- Use one agent if the task fits one context. A graph costs more and fails in more ways.
- Give each worker a disjoint set of files. Two workers never write the same file.
- Shared files (lockfiles, schemas, config, `AGENTS.md`): only the orchestrator changes them, after it combines the results.
- Each worker that writes files uses its own `git worktree` on its own branch: `agent/<task>-<worker>`. Never two writers in one working tree.
- Read-only workers (search, review) can share the working tree.
- Set a limit: number of workers and total budget. Write it in the state file.

## Edges
- Give a worker only what it needs: its contract, its files, and the facts it cannot find. Not your full history.
- A worker returns: changed files, commands with exit codes, open risks. Not "done".
- Workers do not talk to each other. All coordination goes through the orchestrator.

## Combine the results
1. Check that each result touches only its owned files.
2. If the task does not allow merges, run the checks and the verifier on each worker branch. Do not merge. Go to step 7.
   Report each worker branch with its check output for a human to merge.
3. If the task allows merges, merge one result at a time in a worktree of the task branch. Never merge in a working tree that has user changes.
   Run the checks after each merge.
4. On a conflict, stop that merge. Give the conflict to one worker or resolve it yourself. Do not keep both versions without a check.
5. Run the full checks and the verifier on the merged result.
6. A worker that failed is a failed attempt. Apply the Failure recovery limit. Do not restart it with the same contract.
7. Remove each worker worktree with `git worktree remove` when its result is merged or reported. Keep the branch.

## Do not
- Do not start two agents on the same goal and keep the "better" result without a check.
- Do not let a worker merge, push, or change shared files.
- Do not count work from a worker as verified without its command output.
