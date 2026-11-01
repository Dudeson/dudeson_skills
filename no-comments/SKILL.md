---
name: no-comments
description: Make code self-explanatory by deleting comments the code should carry and refactoring so it does. Use when preparing or reviewing a PR, or when asked to clean up comments.
---

# No comments

Make the code say it. A comment survives only when the code cannot.

## Scope

The caller's files or diff. Otherwise the current diff against the base branch (default `main`), including the working tree.

## Keep list

These survive untouched:

- Doc comments on a public API: exported functions, types, modules.
- License and legal headers.
- Issue, RFC, or spec links that explain a constraint the code cannot express.
- Tool directives: `prettier-ignore`, `eslint-disable` and `@ts-expect-error` with a reason, pragmas, shebangs.
- `TODO` and `FIXME`.

## Steps

1. Sort every other comment in scope by what it carries:
   - **Nothing the reader needs.** Narration of the next line, section banners, commented-out code, and decision history (who agreed what, when; git holds that). Delete.
   - **A reason the code could show.** Delete it and make the code show it: rename the symbol, extract a named function, pull the magic value into a named constant, add a type. Same file, behaviour unchanged.
   - **A reason no local refactor can carry.** Keep it, cut to one line.
2. Bare suppressions (`eslint-disable`, `@ts-ignore` with no reason): make the code pass the rule. If it cannot, switch `@ts-ignore` to `@ts-expect-error` and put the reason on the same line.
3. Run the repo's typecheck and lint. Done when every comment in scope is deleted, on the keep list, or kept with a one-line reason, and the checks are green.

## Report

Files touched and deletion count. Then one line each for: a refactor (symbol, what the comment said, what the code now says), a kept comment outside the keep list with its reason, a suppression left standing with its reason.
