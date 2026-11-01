# dudeson_skills

Personal agent skills shared across machines (MacBook, Beelink) and across every
Claude Code config dir plus Codex. One folder per skill, each with a `SKILL.md`.

## New machine

Clone anywhere; `link.sh` finds the repo from its own location.

```bash
git clone git@github.com:Dudeson/dudeson_skills.git <path>
<path>/link.sh
```

Current clones:

- MacBook: `~/Documents/web_works/personal/dudeson_skills`
- Beelink: `~/web_works/dudeson_skills`

`link.sh` symlinks every skill here into `~/.agents/skills` (read by Codex and by
`~/.claude/skills` when that is a symlink) and into the `skills/` folder of every
Claude config dir it finds: `~/.claude`, `~/.claude-ondra`, `$CLAUDE_CONFIG_DIR`,
and the home path of each Claude provider instance in T3 Code's settings.
It is safe to rerun at any time.

## Update a skill

Edit it here, then:

```bash
git commit -am "Update <skill>" && git push
```

On the other machine: `git pull`. The symlinks already point at the clone, so the
change is live in the next thread.

## Add a skill

1. Create `<skill-name>/SKILL.md` with `name:` and `description:` frontmatter.
   Names must be lowercase letters, digits and hyphens only.
2. Run `./link.sh`, then commit and push. `git commit -am` skips new folders, so
   add it explicitly:

   ```bash
   git add <skill-name> && git commit -m "Add <skill-name>" && git push
   ```

3. On each other machine: `git pull && ./link.sh`.

## Move an existing skill in

```bash
mv ~/.agents/skills/<name> ./<name> && ./link.sh
```
