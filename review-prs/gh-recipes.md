# gh recipes for review-prs

`gh` fills `{owner}` and `{repo}` itself. `<me>` is the login from `gh api user --jq .login`; substitute it as you do `<n>`.

## Repo

```
git rev-parse --show-toplevel
gh repo view --json nameWithOwner --jq .nameWithOwner
```

Either one failing means the current directory is not in a GitHub repo. Run every other call from the top level the first one prints.

## Discover

```
gh pr list --search "is:open draft:false review-requested:@me" \
  --json number,title,url,author,headRefOid,headRefName,baseRefName
```

A named PR: `gh pr view <n> --json number,title,url,author,headRefOid,headRefName,baseRefName,state`.

## Changed paths

```
gh pr view <n> --json files --jq '.files[].path'
```

## The user's reviews on a PR

```
gh api "repos/{owner}/{repo}/pulls/<n>/reviews" --paginate \
  --jq '.[] | select(.user.login=="<me>") | {id, state, commit_id, submitted_at}'
```

`state: PENDING` is an unsubmitted review the user started by hand. The latest submitted review is the last entry with any other state; its `commit_id` is the re-review fixed point.

The approval stands when the last entry with state `APPROVED`, `CHANGES_REQUESTED` or `DISMISSED` is `APPROVED`. A later `COMMENTED` review leaves it standing.

## Fetch

For every PR whose commits you read or that gets a worktree:

```
git fetch origin "pull/<n>/head:refs/review/<n>" "<base>"
```

The same call refreshes `origin/<base>`, the fixed point of a first review.

## Author commits since a review

```
git merge-base --is-ancestor <commit_id> refs/review/<n>   # exit 1: rebased away
git log --first-parent --no-merges --oneline <commit_id>..refs/review/<n>
```

Empty log: only base merges since the review.

## Worktree

```
git worktree add --detach .claude/worktrees/review-<n> refs/review/<n>
```

Clean up:

```
git worktree remove --force .claude/worktrees/review-<n>
git update-ref -d refs/review/<n>
git worktree prune
```

`--force` is safe here: the worktree is detached, read-only and created by this run.

## Create the review

Write the payload to a file in the scratchpad, then:

```
gh api -X POST "repos/{owner}/{repo}/pulls/<n>/reviews" --input <payload.json> --jq '{id, state, html_url}'
```

```json
{
  "commit_id": "<reviewed head sha>",
  "event": "COMMENT",
  "body": "",
  "comments": [
    { "path": "src/x.ts", "line": 226, "side": "RIGHT", "body": "..." }
  ]
}
```

- `event` is always `COMMENT`. Left out, GitHub creates an unsubmitted review that only the user sees.
- A review with no inline comments needs a non-empty `body`.
- `422` naming a line or path: that line is outside the diff. Move the finding into `body`, led by its `path:line`, and send once more.
- `422` "one pending review per pull request": the user has an unsubmitted review on the PR. Report the PR as skipped.
