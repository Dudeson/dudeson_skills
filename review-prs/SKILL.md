---
name: review-prs
description: Review the frontend PRs in the current repo where my review is requested and post the findings worth raising as one GitHub comment review per PR. Pass PR numbers to review exactly those, --no-post to get the review in chat only.
argument-hint: "[pr ...] [--no-post]"
disable-model-invocation: true
---

# Review PRs

You are the dispatcher. You build the **queue**, hand each PR to its own **reviewer** sub-agent, and post what comes back as one GitHub review per PR. The review goes out under the user's name, so it is always a comment review: approving and requesting changes stay with the user.

Read [gh-recipes.md](gh-recipes.md) before step 1. It holds every `gh` and `git` call this run makes, with their failure cases.

## 1. Build the queue

The **repo** is the git repository that contains the current directory, with its GitHub remote. When the current directory is outside one, the run ends there: report "not in a GitHub repo".

- **PR numbers or URLs in the arguments**: those PRs are the queue.
- **No PR arguments**: every open, non-draft PR in the repo where the user's review is requested.

A **frontend file** is a path inside the repo's client workspace: the directory tree that holds the web and mobile apps and the packages they share. In a repo that is all frontend, that is every path. Settle the workspace once from the repo layout and use it for every PR in the run.

For each PR in the queue read its state, the head commit, the head and base branches, the changed paths and the user's own reviews. Then settle it as **review**, **re-review** or **skip**, by the first row that fits:

| State of the PR | Outcome |
|---|---|
| Closed or merged | skip: not open |
| The user wrote it | skip: own PR |
| No frontend files changed | skip: no frontend changes |
| The user's approval stands | skip: already approved |
| The user has an unsubmitted review on it, and this run posts | skip: unsubmitted review in the way |
| The user's latest submitted review is on the head commit | skip: reviewed at head |
| Earlier review exists, and every commit since it is a merge of the base branch | skip: only base merges since review |
| Earlier review exists, with new author commits since | re-review, fixed point is the commit of that review |
| No review from the user | review, fixed point is `origin/<base>` |

A re-review whose earlier commit is no longer an ancestor of the head was rebased away. Treat it as a first review and say so in the report.

Done when every PR in the queue has one outcome. An empty queue ends the run: report "nothing to review".

## 2. Dispatch the reviewers

Create one detached worktree per PR to review, at its head commit, with no install. The review only reads code.

Then dispatch one reviewer per PR, all in a single message so they run in parallel, four at a time when the queue is longer. Each reviewer's prompt is the line "Read `<absolute path to reviewer-brief.md>` and follow it", plus these inputs:

- PR number, URL and title
- head and base branch names
- worktree path
- head commit
- fixed point
- `review` or `re-review`
- the frontend paths the PR changes

Keep the brief out of your own context. It belongs to the reviewer.

A return counts only when it carries its `Spec:`, `Standards read:` and `Axes:` lines. Without them, the PR's outcome is `review failed: axes not run`, and its findings stay unposted.

Once every reviewer has returned its findings or an error, remove every worktree and ref this run created.

Done when `git worktree list` and `git for-each-ref refs/review` show nothing from this run.

## 3. Post

For each PR that came back with findings, submit one `COMMENT` review on the reviewed head commit:

- A finding with a diff line becomes an inline comment on that line.
- A finding without one goes in the review body, led by its `path:line`.
- The body is empty when every finding is inline.
- Comment text goes out exactly as the reviewer wrote it.

A PR with zero findings gets no review.

With `--no-post`, GitHub stays untouched. The findings go in the report instead.

## 4. Report

One row per PR in the queue:

| PR | Outcome | Link |
|---|---|---|
| #101 title | posted, 3 findings | review URL |
| #102 title | skipped: no frontend changes | PR URL |
| #103 title | no findings | PR URL |
| #104 title | review failed: the reviewer's cause | PR URL |

Under the table, per PR:

- **Posted**: one line per finding, `path:line` and its gist.
- **`--no-post`**: every finding in full, `path:line` then the comment text, ready to post as written.
- **Dropped**: the findings the reviewer dropped, one line each with the reason. That list is how the user checks the bar is set right.
- **Note**: any `NOTE` line a reviewer returned, as written, and "no spec available" when its `Spec:` line says so.
- **Axes**: the reviewer's `Axes:` and `Standards read:` lines, as written.

The run is done when every queued PR has a row.
