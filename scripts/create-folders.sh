#!/usr/bin/env bash
# Create the standard host folder layout. This is safe to run repeatedly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/create-folders.sh [--dry-run]

Creates the standard workstation folders under your home directory.
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

section "Folder creation"

folders=(
  "${HOME}/Projects"
  "${HOME}/Boxes"
  "${HOME}/Boxes/projects"
  "${HOME}/VMs"
  "${HOME}/Scratch"
  "${HOME}/Games"
  "${HOME}/Games/SteamLibrary"
  "${HOME}/Downloads/Quarantine"
)

for folder in "${folders[@]}"; do
  log "Ensuring $folder"
  ensure_dir "$folder"
done

log "Folder creation complete."
