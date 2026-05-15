#!/usr/bin/env bash
# Configure Flathub and install desktop applications from config/flatpaks.txt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install-flatpaks.sh [--dry-run]

Ensures Flathub exists and installs configured Flatpak applications.
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

section "Flatpak install"
if ! command_exists flatpak; then
  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    warn "flatpak is not installed, but continuing because dry-run mode is enabled."
  else
    die "flatpak is not installed. Run install-host-packages.sh first."
  fi
fi

log "Ensuring Flathub remote exists."
run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

mapfile -t flatpaks < <(read_config_lines "${REPO_ROOT}/config/flatpaks.txt")

if [[ "${#flatpaks[@]}" -eq 0 ]]; then
  warn "No Flatpak applications configured."
  exit 0
fi

for app_id in "${flatpaks[@]}"; do
  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    log "Would ensure Flatpak is installed: $app_id"
    run flatpak install -y flathub "$app_id"
    continue
  fi

  if flatpak info "$app_id" >/dev/null 2>&1; then
    log "Already installed: $app_id"
  else
    log "Installing: $app_id"
    run flatpak install -y flathub "$app_id"
  fi
done

log "Flatpak install complete. Some apps may appear after logging out and back in."
