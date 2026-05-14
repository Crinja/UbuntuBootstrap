#!/usr/bin/env bash
# Configure the shared ai-code Distrobox once.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/setup-ai-code.sh [--dry-run]

Configures the shared ai-code Distrobox with Claude Code and Codex CLI.
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

section "AI coding tools setup"

box_name="ai-code"
setup_script="${REPO_ROOT}/boxes/ai-code.sh"

[[ -f "$setup_script" ]] || die "Missing setup script: $setup_script"

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  log "Would configure '${box_name}' with ${setup_script}."
  exit 0
fi

command_exists distrobox-enter || die "distrobox-enter is not installed."

if ! distrobox_exists "$box_name"; then
  die "Distrobox '${box_name}' does not exist. Run ./bootstrap.sh first."
fi

distrobox-enter --name "$box_name" -- bash -s < "$setup_script"
