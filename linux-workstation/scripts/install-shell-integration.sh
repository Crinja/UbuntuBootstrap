#!/usr/bin/env bash
# Add workstation helper commands to the user's Bash startup file.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install-shell-integration.sh [--dry-run]

Adds an idempotent block to ~/.bashrc so the ws-* helper commands are available
in new Bash terminals.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n)
      export WS_DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

section "Bash shell integration"

bashrc="${HOME}/.bashrc"
source_file="${REPO_ROOT}/dotfiles/bashrc.append"
marker_start="# >>> linux-workstation ws commands >>>"
marker_end="# <<< linux-workstation ws commands <<<"
quoted_source_file="$(printf '%q' "$source_file")"
snippet="$(cat <<EOF
${marker_start}
if [ -f ${quoted_source_file} ]; then
  source ${quoted_source_file}
fi
${marker_end}
EOF
)"

[[ -f "$source_file" ]] || die "Missing shell integration snippet: $source_file"

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  log "Would ensure ${bashrc} sources ${source_file}."
  exit 0
fi

touch "$bashrc"

if grep -Fxq "$marker_start" "$bashrc"; then
  tmp_file="$(mktemp)"
  awk -v start="$marker_start" -v end="$marker_end" -v snippet="$snippet" '
    $0 == start {
      print snippet
      in_block = 1
      next
    }
    $0 == end {
      in_block = 0
      next
    }
    !in_block {
      print
    }
  ' "$bashrc" >"$tmp_file"
  mv "$tmp_file" "$bashrc"
  log "Updated existing workstation PATH block in ${bashrc}."
elif grep -Fq "$source_file" "$bashrc"; then
  log "${bashrc} already sources ${source_file}."
else
  {
    printf '\n%s\n' "$snippet"
  } >>"$bashrc"
  log "Added workstation PATH block to ${bashrc}."
fi

log "Open a new terminal or run: source ~/.bashrc"
