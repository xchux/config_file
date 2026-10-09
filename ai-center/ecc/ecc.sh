#!/usr/bin/env bash
# Install ECC (https://github.com/affaan-m/ECC) into every AI harness from one place.
#
#   ./ecc.sh home                         Claude Code + Codex native plugins (user-level)
#   ./ecc.sh project <dir> [targets...]   Project-local adapters, default: cursor antigravity
#   ./ecc.sh doctor <dir> [targets...]    Check project-local adapters
#   add --dry-run before the subcommand to preview
#
# Module selection for project targets lives in ecc-install.json (shared by all targets).
set -euo pipefail

ECC_VERSION="2.2.0"   # bump here to upgrade every harness
ECC_MARKETPLACE="affaan-m/ECC"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HERE/ecc-install.json"

DRY=0
[[ "${1:-}" == "--dry-run" ]] && { DRY=1; shift; }
CMD="${1:-}"; shift || true

run() { if ((DRY)); then echo "[dry-run] $*"; else "$@"; fi; }
ecc() { npx -y "ecc-universal@$ECC_VERSION" "$@"; }

home() {
  if command -v claude >/dev/null; then
    # Marketplace + enabledPlugins are also declared in ../claude/settings.json.
    run claude plugin marketplace add "https://github.com/$ECC_MARKETPLACE.git" || true
    run claude plugin install ecc@ecc || run claude plugin marketplace update ecc
  else
    echo "skip    claude (not on PATH)"
  fi

  if command -v codex >/dev/null; then
    run codex plugin marketplace add "$ECC_MARKETPLACE"
    run codex plugin add ecc@ecc
  else
    echo "skip    codex (not on PATH)"
  fi
}

project() {
  local dir="${1:?usage: ecc.sh project <dir> [targets...]}"; shift
  local targets=("$@")
  ((${#targets[@]})) || targets=(cursor antigravity)
  local t flags=()
  ((DRY)) && flags+=(--dry-run)
  for t in "${targets[@]}"; do
    echo "== ecc install --target $t ($dir)"
    (cd "$dir" && ecc install --config "$CONFIG" --target "$t" "${flags[@]}")
  done
}

doctor() {
  local dir="${1:?usage: ecc.sh doctor <dir> [targets...]}"; shift
  local targets=("$@")
  ((${#targets[@]})) || targets=(cursor antigravity)
  local t
  for t in "${targets[@]}"; do
    (cd "$dir" && ecc doctor --target "$t")
  done
}

case "$CMD" in
  home)    home ;;
  project) project "$@" ;;
  doctor)  doctor "$@" ;;
  *) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
