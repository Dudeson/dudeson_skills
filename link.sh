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

# 2. Collect Claude config dirs: the defaults, CLAUDE_CONFIG_DIR, and every
#    Claude provider instance T3 Code has configured with its own home path.
CLAUDE_DIRS=("$HOME/.claude" "$HOME/.claude-ondra")
[ -n "${CLAUDE_CONFIG_DIR:-}" ] && CLAUDE_DIRS+=("$CLAUDE_CONFIG_DIR")
T3_SETTINGS="${T3CODE_HOME:-$HOME/.t3}/userdata/settings.json"
if [ -f "$T3_SETTINGS" ] && command -v python3 >/dev/null 2>&1; then
  while IFS= read -r p; do
    [ -n "$p" ] && CLAUDE_DIRS+=("$p")
  done < <(python3 -I - "$T3_SETTINGS" <<'PY'
import json, os, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
for inst in data.get("providerInstances", {}).values():
    if inst.get("driver") != "claudeAgent":
        continue
    home = (inst.get("config") or {}).get("homePath") or ""
    if home:
        print(os.path.expanduser(home))
PY
)
fi

# 3. Every Claude config dir -> per-skill links to everything in ~/.agents/skills
#    (skips the account-synced bucket, which each Claude account manages itself)
for cfg in "${CLAUDE_DIRS[@]}"; do
  [ -d "$cfg" ] || continue
  dest="$cfg/skills"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$AGENTS_SKILLS" ]; then
    echo "ok: $dest already points at $AGENTS_SKILLS"
    continue
  fi
  mkdir -p "$dest"
  n=0
  for skill in "$AGENTS_SKILLS"/*/; do
    skill="${skill%/}"
    name="$(basename "$skill")"
    [ "$name" = synced ] && continue
    [ -f "$skill/SKILL.md" ] || continue
    link "$skill" "$dest/$name"
    n=$((n+1))
  done
  echo "ok: $dest has links for $n skills"
done

echo "skills linked from $REPO_DIR"
