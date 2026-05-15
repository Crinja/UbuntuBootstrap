#!/usr/bin/env bash
# Remove unused Flatpak runtimes after confirmation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/cleanup-unused-flatpaks.sh [--dry-run] [--yes]

Runs:
  flatpak uninstall --unused

No cleanup happens without confirmation unless --yes is passed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n)
      export WS_DRY_RUN=1
      shift
      ;;
    --yes|-y)
      export WS_ASSUME_YES=1
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

section "Flatpak cleanup"
command_exists flatpak || die "flatpak is not installed."

if confirm "Remove unused Flatpak runtimes and extensions?"; then
  run flatpak uninstall --unused
else
  log "Cleanup cancelled."
fi
