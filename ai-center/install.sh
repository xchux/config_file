#!/usr/bin/env bash
# Link ai-center configs into each tool's home location.
# Existing files are backed up as <file>.bak.<timestamp> before linking.
#
# Usage: ./install.sh [--dry-run] [all|claude|codex|agy|cursor]
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"
DRY=0
[[ "${1:-}" == "--dry-run" ]] && { DRY=1; shift; }
TARGET="${1:-all}"

run() { if ((DRY)); then echo "[dry-run] $*"; else "$@"; fi; }

link() { # link <src> <dest>
  local src="$1" dest="$2"
  run mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "ok      $dest"; return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    run mv "$dest" "$dest.bak.$TS"
    echo "backup  $dest -> $dest.bak.$TS"
  fi
  run ln -s "$src" "$dest"
  echo "link    $dest -> $src"
}

link_dir_items() { # link each child of <src_dir> into <dest_dir>
  local src_dir="$1" dest_dir="$2" item
  for item in "$src_dir"/*; do
    [[ -e "$item" ]] || continue  # empty or missing src_dir: unmatched glob
    link "$item" "$dest_dir/$(basename "$item")"
  done
}

common() {
  link "$SRC" "$HOME/.config/ai-center"
  # Shared Agent Skills path (Codex reads ~/.agents/skills)
  link_dir_items "$SRC/skills" "$HOME/.agents/skills"
}

claude() {
  link "$SRC/claude/settings.json" "$HOME/.claude/settings.json"
  link "$SRC/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
  link_dir_items "$SRC/skills"         "$HOME/.claude/skills"
  # User-scope MCP lives in ~/.claude.json (managed by the CLI), so register via CLI.
  # `command` / `type -P`: this function is itself named claude; a bare `claude` recurses.
  if type -P claude >/dev/null; then
    local name json
    while IFS=$'\t' read -r name json; do
      run command claude mcp remove -s user "$name" >/dev/null 2>&1 || true
      run command claude mcp add-json -s user "$name" "$json"
    done < <(python3 -c 'import json, sys
for k, v in json.load(open(sys.argv[1]))["mcpServers"].items():
    print(k, json.dumps(v), sep="\t")' "$SRC/claude/mcp.json")
  else
    echo "skip    claude MCP ('claude' not on PATH)"
  fi
}

codex() {
  link "$SRC/codex/config.toml" "$HOME/.codex/config.toml"
  link "$SRC/AGENTS.md"         "$HOME/.codex/AGENTS.md"
  link_dir_items "$SRC/agents/codex" "$HOME/.codex/agents"
}

cursor() {
  link "$SRC/ide/cursor/mcp.json" "$HOME/.cursor/mcp.json"
}

agy_() { # agy (Antigravity CLI); the Antigravity IDE shares ~/.gemini/config
  local cfg="$HOME/.gemini/config"
  link "$SRC/AGENTS.md" "$cfg/AGENTS.md"
  link_dir_items "$SRC/skills" "$cfg/skills"
  # mcp_config.json has no env interpolation, so register via CLI: ${VAR} is expanded here
  # and the token lands only in ~/.gemini/config/mcp_config.json, never in this repo.
  if command -v agy >/dev/null; then
    local name args
    while IFS=$'\t' read -r name args; do
      if [[ -z "$args" ]]; then
        echo "skip    agy MCP $name (unset env var in headers/env)"; continue
      fi
      # Not via run(): the expanded args contain the token, keep it off the screen.
      if ((DRY)); then echo "[dry-run] agy mcp add ... $name"; continue; fi
      eval "agy mcp add $args" >/dev/null
      echo "mcp     agy $name"
    done < <(python3 -c 'import json, os, re, shlex, sys
for k, v in json.load(open(sys.argv[1]))["mcpServers"].items():
    flags = []
    for h, val in v.get("headers", {}).items():
        flags += ["-H", f"{h}: {os.path.expandvars(val)}"]
    for e, val in v.get("env", {}).items():
        flags += ["-e", f"{e}={os.path.expandvars(val)}"]
    if any(re.search(r"\$\{?\w+", f) for f in flags):
        print(k, "", sep="\t"); continue
    target = [v["url"]] if v.get("type") == "http" else ["--", v["command"], *v.get("args", [])]
    print(k, shlex.join([*flags, k, *target]), sep="\t")' "$SRC/mcp/servers.json")
  else
    echo "skip    agy MCP ('agy' not on PATH)"
  fi
}

case "$TARGET" in
  all) common; claude; codex; agy_; cursor ;;
  agy) common; agy_ ;;
  claude|codex|cursor) common; "$TARGET" ;;
  *) echo "unknown target: $TARGET" >&2; exit 1 ;;
esac

cat <<'EOF'

Done. Remaining manual steps:
  - export GITHUB_PERSONAL_ACCESS_TOKEN=... BRAVE_API_KEY=...   (add to ~/.zshrc)
  - agy: re-run `./install.sh agy` after setting / rotating those keys (they are baked in)
  - VS Code / Cursor / Antigravity settings: copy ide/vscode/settings.json into the IDE's User settings
  - Per-repo: copy ide/vscode/mcp.json -> .vscode/mcp.json, ide/cursor/rules -> .cursor/rules,
              agy/rules -> .agents/rules
EOF
