---
name: test-in-chrome
description: Visually verify completed frontend work in the user's real Chrome browser (logged-in session) via the Claude in Chrome tools — not the in-app browser. Use ONLY when the user explicitly invokes /test-in-chrome (optionally with a URL argument) — never trigger automatically after finishing work.
---

# Test in Chrome

Verify just-completed work in the user's **real Chrome** (claude-in-chrome tools), where they have a logged-in session. Do NOT use the in-app Browser (`mcp__Claude_Browser__*`) for this.

## 1. Load tools (one batched ToolSearch call)

```
ToolSearch "select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__find,mcp__claude-in-chrome__form_input,mcp__claude-in-chrome__read_console_messages,mcp__claude-in-chrome__read_network_requests,mcp__claude-in-chrome__tabs_create_mcp"
```

## 2. Pick the target tab

Priority order:

1. **URL argument** — if the user gave a URL (as skill args or in the message), use it. Bare `localhost:PORT/...` is fine; add `http://`.
2. **Discover the running dev app** — figure out where the app under test is served:
   - check open Chrome tabs (`tabs_context_mcp`) for a localhost tab matching the project;
   - check how the dev server is running: listening ports (`lsof -iTCP -sTCP:LISTEN`), dev-server logs/terminal, or the port configured in the project (package.json scripts, `.claude/launch.json`, env files).
   - Reuse an existing matching tab when there is one (select it, then navigate to the same URL to reload so the latest code is picked up).
3. **Neither** — ask the user for the URL. Don't guess deep routes.

If the repo hosts multiple apps, infer which one from the files just changed.

## 3. Verify the work

Always do all of these, scoped to the change just made:

1. **Reload & look** — navigate/reload, take a screenshot, confirm the changed UI renders as intended (layout, copy, states).
2. **Exercise the feature** — click through the flow the change introduced/affected: open the dialog, fill the form, trigger the new state. Use `read_page`/`find` for stable refs; screenshot key states.
3. **Console & network** — after interacting, check `read_console_messages` (errors/warnings) and `read_network_requests` for failed requests related to the change.

## 4. Constraints

- The session is the user's real logged-in account: do not perform destructive or hard-to-undo actions (delete, send, publish, submit to third parties) — stop and ask first.
- Creating throwaway test data (draft docs, form entries) inside the local dev app is fine; mention what was created.
- If the page 404s or the app isn't running, report it and suggest starting the dev server — don't silently switch to the in-app browser.

## 5. Report

End with a short summary:

- ✅ / ❌ per thing verified (render, interaction, console, network)
- Screenshots of the final state
- Anything that looks off, even if unrelated to the change
