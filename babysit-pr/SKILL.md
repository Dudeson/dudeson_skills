---
name: babysit-pr
description: Babysit an open GitHub PR until it is merge-ready. Fixes failing checks, answers review comments, merges the base branch on conflicts, then hands back for the merge. Use when the user says babysit, watch, or keep green about a PR, or names a PR to shepherd.
---

# Babysit PR

Runs inside T3 Code. `watch_pull_request` wakes this thread on failed checks, passed required checks, new comments or reviews, and conflicts. The loop is: a wake arrives, you handle everything the PR currently carries, you end the turn, T3 wakes you again. Merging is the author's call; you bring the PR to merge-ready and hand back.

## Start

1. Resolve the PR. Argument is a number or URL; with no argument, use the PR for the current branch:
   ```
   gh pr view --json url,number,headRefName,baseRefName,state
   ```
   No open PR: say so and stop.
2. Check out the head branch and pull it.
3. Run one full **sweep** (below) on the PR as it stands. The watch only wakes you for events after it starts, so anything already on the PR is yours now.
4. `watch_pull_request` the PR, then end the turn.
5. Only when this thread did work before `/babysit-pr` was invoked (implementation, reviews, browser checks), compact it after the watch starts and before the turn ends:
   1. Load `mcp__t3-code__orchestrator_capabilities` and `mcp__t3-code__t3_thread_send` with ToolSearch. Both are deferred.
   2. Call `orchestrator_capabilities`. It returns this thread's id as `parentThreadId`.
   3. Call `t3_thread_send` with `threadId: <that id>`, `message: "/compact"` and `mode: "queue"`. The text must be exactly `/compact`; T3 matches the whole message.
   4. End the turn. T3 runs the compaction as the next turn, and the watch stays on.

   A thread that started with `/babysit-pr` skips this step. Its context is already small.

## Sweep

A sweep runs at start and on every wake. Gather state first, then work the three concerns in this order: conflicts, then checks, then comments. Conflicts go first so checks run against current code; comment fixes go last so they ride the same push.

```
gh pr view <n> --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,reviews,comments
```
Review threads need GraphQL: see [gh-recipes.md](gh-recipes.md).

### Conflicts

`mergeable` is `CONFLICTING` or `mergeStateStatus` is `BEHIND` or `DIRTY`: merge the base branch into the head branch.
```
git fetch origin && git merge origin/<base>
```
Resolve each conflict so both sides' intent survives, run the project's test command, push. Done when `mergeable` reads `MERGEABLE`.

### Failing checks

For every check in `statusCheckRollup` with conclusion `FAILURE`:

1. Read the cause: `gh run view <run-id> --log-failed` for Actions, the `detailsUrl` otherwise.
2. Reproduce locally with the project's equivalent command (the script `package.json`, `Makefile`, or the workflow file names).
3. Fix, confirm the local command passes, commit, push.

A check whose log shows only infrastructure trouble (runner lost, network timeout, nothing touching the diff) gets one `gh run rerun <run-id> --failed`.

Each push or rerun against the same check is a **strike**. Two strikes on one check is a handback.

### Review comments

Work every unresolved review thread and every review body that is new since the last sweep. Judge each on its merits, bot or human alike:

- **Agree**: change the code. After the push, reply naming the commit, then resolve the thread.
- **Disagree**: reply with the reason and leave the thread open. A human review in `CHANGES_REQUESTED` state that you would decline is a handback.
- **Ambiguous**: reply with the question that would settle it and leave the thread open.
- **Design question** (scope, approach, product decision): reply "checking with the author" and handback.

Every reply reads as a teammate wrote it: one plain sentence that states the fact (what changed, why it stays, what is unclear), written for the reviewer. Add a second sentence or a code line only when the reason needs it. Examples:

- `Fixed in a1b2c3d.`
- `Kept as is: the null check runs earlier in validateInput, so this branch is unreachable.`
- `Do you mean the retry count or the retry delay?`

When every comment from a `CHANGES_REQUESTED` reviewer is handled, re-request their review (recipe in `gh-recipes.md`).

### Push

One commit per concern, message in the style of `git log` for that repo. The project's test and lint commands pass locally before each push. Plain `git push`: the merge strategy means history is never rewritten.

### Report

End every sweep with a short chat message: what was wrong, what you pushed (commit SHAs), what is still pending. Then end the turn. The watch stays on; calling `watch_pull_request` again is only for a fresh start.

## Dropped watch

T3 sends "stopped watching pull request" after 8 failed reads. Follow this section, not the notice.

1. Run one sweep with `gh`, then continue here instead of ending the turn.
2. Read T3's reason:
   ```
   grep -h 'pull request watch check failed' ~/.t3/userdata/logs/server.trace.ndjson* | grep '<owner>/<repo>#<n>\\"' | grep -o 'reason\\": \\"[a-z-]*' | sort | uniq -c
   ```
   No lines: run the `ls-remote` check in step 3 anyway.
3. `not-found`: run `git ls-remote origin refs/pull/<n>/head`.
   - Empty: GitHub lost the PR's head ref, and every re-arm fails the same way. Hand back naming the missing `refs/pull/<n>/head`: the next push to the head branch should restore it; closing and reopening does not.
   - Present: T3's credential can't see the repo. Hand back with that.
4. Any other reason: re-arm once. A second drop in the same run is a handback.

## Handback

Hand back on any of:

- **Merge-ready**: all checks green, `reviewDecision` is `APPROVED` (or the repo requires no review), zero unresolved threads, `mergeable` is `MERGEABLE`.
- **Two strikes** on one check.
- **Design question** from a reviewer.
- **Changes requested** by a human that you would decline.
- **Dropped watch**, per the section above.

On handback: `unwatch_pull_request`, then a final message with the PR URL, head SHA, check and review state, and the single decision the author needs to make. Merging stays with the author.
