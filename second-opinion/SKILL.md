---
name: second-opinion
description: Second opinion on the current changes from another model, run as a T3 delegate. Defaults to the newest GPT Sol at high effort; pass a model or an effort to override. Fixes the findings that hold up, declines the rest with a reason, asks the author before judgment calls.
argument-hint: "[model] [effort]"
disable-model-invocation: true
---

# Second opinion

Runs inside T3 Code. The **reviewer** is another model that reads the change with fresh eyes and no history; you triage with the history it lacks. The reviewer can be wrong, so every finding is **confirmed** against the code before it changes anything.

## Reviewer

Resolve the reviewer from the arguments against `orchestrator_capabilities`. Call it once if this thread has not yet.

- **Model.** The argument that names a model, matched against the listed ids. A family name such as `astra` means its highest version. `search` finds a model the short list omits. When two provider instances list the model, use this thread's own. With no model argument, take the highest-versioned `gpt-*-sol` on the Codex provider.
- **Effort.** The argument that is one of the model's effort values. With no effort argument, `high`.

When no enabled provider lists the model, or the model lacks the effort, name the available choices and stop.

## Scope

The diff since the merge-base with the base branch (default `main`), working tree included:

```
git diff $(git merge-base HEAD origin/main)
```

Use the local branch when there is no remote. Empty diff: say so and stop.

## Steps

1. **Brief the reviewer.** One `delegate_task`:
   - `mode: "wait"`, `timeoutMs: 1800000`, `role: "review"`, `title: "Second opinion: <model>"`
   - `target`: the reviewer's provider instance and model, with the effort set in `options` under the model's own effort option id
   - `task`: the brief below, filled in. The reviewer starts with no history, so the intent paragraph is all it knows about why the change exists. Take it from this thread, or from the branch's commits when the change was made elsewhere.

   ```
   Review the changes on this branch as a second pair of eyes. Read only; change nothing.

   Intent: <what the change is meant to do, and anything deliberately left out>
   Base: <base ref>. Diff: git diff <merge-base sha>. Working tree edits are part of the change.

   Find defects: wrong behaviour, a missed case, a broken contract or invariant, a regression for an existing caller, a security or data-loss hole, a test that asserts the wrong thing. Read enough surrounding code to be sure before you report. Style and preference are out of scope unless they hide a defect.

   Return a ranked list. Each finding: severity (high/medium/low), file:line, what breaks, how to reproduce or see it, the fix you would make. "No findings" is a valid answer; say what you checked.
   ```

   Done when the reviewer's result is in hand. On a timeout, follow the result's `next`.

2. **Triage** every finding into one bucket, after reading the code it points at:
   - **Fix**: the defect is real. Fix it in place.
   - **Decline**: the code disproves it, it is preference or style, or it is outside the change. Keep the reason in one sentence.
   - **Ask**: fixing it is a choice the author owns: a behaviour change, an API shape, a trade-off (speed vs simplicity, strictness vs compatibility), scope worth adding.

3. **Ask** the author about the Ask bucket in one question with an option per finding (the reviewer's fix, keep as is) and your recommendation marked. Act on the answers. Skip when the bucket is empty.

4. **Check**: run the project's test and lint commands for the touched files. Fixes stay uncommitted for the author's review.

## Report

The reviewer's model, effort and verdict in one line, then one line per finding under Fixed (what changed), Declined (why), and Decided (the author's call and what you did).
