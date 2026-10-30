# gh recipes for babysit-pr

GitHub's review-thread model is GraphQL-only. These are the calls the sweep needs beyond `gh pr view`. Set `OWNER`, `REPO`, `N` from `gh pr view --json url`.

## List review threads

```
gh api graphql -F owner="$OWNER" -F repo="$REPO" -F n="$N" -f query='
query($owner:String!,$repo:String!,$n:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$n){
      reviewThreads(first:100){
        nodes{
          id isResolved isOutdated path line
          comments(first:30){
            nodes{ databaseId author{login} body createdAt url }
          }
        }
      }
    }
  }
}'
```
`id` (starts `PRRT_`) resolves the thread. `databaseId` of the first comment is the reply target.

## Reply in a thread

```
gh api -X POST "repos/$OWNER/$REPO/pulls/$N/comments/<first-comment-databaseId>/replies" -f body='Fixed in abc1234.'
```

## Resolve a thread

```
gh api graphql -F id="PRRT_..." -f query='
mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }'
```

## Reply to a PR-level comment or review body

```
gh pr comment "$N" --body '...'
```

## Re-request a review

```
gh api -X POST "repos/$OWNER/$REPO/pulls/$N/requested_reviewers" -f 'reviewers[]=<login>'
```

## Failed check logs

`statusCheckRollup` entries from `gh pr view` carry `detailsUrl`; for GitHub Actions the run id is the number after `/runs/`.

```
gh run view <run-id> --log-failed
gh run rerun <run-id> --failed
```
