#!/usr/bin/env bash
# Configure or update the Claude and Codex tool boxes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/setup-ai-tools.sh [--dry-run]

Configures or updates:
  claude-code
  codex
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

section "AI tool setup"

tool_boxes=(
  "claude-code:${REPO_ROOT}/boxes/claude-code.sh"
  "codex:${REPO_ROOT}/boxes/codex.sh"
)

for entry in "${tool_boxes[@]}"; do
  setup_script="${entry#*:}"
  [[ -f "$setup_script" ]] || die "Missing setup script: $setup_script"
done

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  for entry in "${tool_boxes[@]}"; do
    box_name="${entry%%:*}"
    setup_script="${entry#*:}"
    log "Would configure '${box_name}' with ${setup_script}."
  done
  exit 0
fi

command_exists distrobox-enter || die "distrobox-enter is not installed."

for entry in "${tool_boxes[@]}"; do
  box_name="${entry%%:*}"
  setup_script="${entry#*:}"

  if ! distrobox_exists "$box_name"; then
    die "Distrobox '${box_name}' does not exist. Run ./bootstrap.sh first."
  fi

  log "Configuring ${box_name}."
  distrobox-enter --name "$box_name" -- bash -s < "$setup_script"
done
