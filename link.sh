#!/usr/bin/env bash
# link.sh - expose every skill in this repo to Claude Code (all config dirs) and Codex.
# Idempotent. Run once after cloning and again whenever you add a new skill folder.
# Works on macOS and Linux. Lives in the root of your skills git repo.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SKILLS="$HOME/.agents/skills"
mkdir -p "$AGENTS_SKILLS"

link() { # link <target-dir> <link-path>
  if [ -e "$2" ] && [ ! -L "$2" ]; then
    echo "skip: $2 is a real directory, move it into the repo first" >&2
    return 0
  fi
  ln -sfn "$1" "$2"
}

# 1. Repo skills -> ~/.agents/skills
#    Codex reads this folder natively; the default Claude instance reaches it via ~/.claude/skills.
for skill in "$REPO_DIR"/*/; do
  skill="${skill%/}"
  [ -f "$skill/SKILL.md" ] || continue
  link "$skill" "$AGENTS_SKILLS/$(basename "$skill")"
done

# 2. Every Claude config dir -> per-skill links to everything in ~/.agents/skills
#    (skips the account-synced bucket, which each Claude account manages itself)
CLAUDE_DIRS=("$HOME/.claude" "$HOME/.claude-ondra")
[ -n "${CLAUDE_CONFIG_DIR:-}" ] && CLAUDE_DIRS+=("$CLAUDE_CONFIG_DIR")
for cfg in "${CLAUDE_DIRS[@]}"; do
  [ -d "$cfg" ] || continue
  dest="$cfg/skills"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$AGENTS_SKILLS" ]; then
    continue  # whole folder already points at the shared library
  fi
  mkdir -p "$dest"
  for skill in "$AGENTS_SKILLS"/*/; do
    skill="${skill%/}"
    name="$(basename "$skill")"
    [ "$name" = synced ] && continue
    [ -f "$skill/SKILL.md" ] || continue
    link "$skill" "$dest/$name"
  done
done

echo "skills linked from $REPO_DIR"
