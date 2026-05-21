#!/usr/bin/env bash
# Configure Flathub and install optional desktop applications from config/flatpaks.txt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install-flatpaks.sh [--dry-run]

Ensures Flathub exists and installs configured Flatpak applications.
The default config installs VS Code only. Add more app IDs to config/flatpaks.txt.
EOF
}

flatpak_is_configured() {
  local wanted="$1"
  local app_id

  for app_id in "${flatpaks[@]:-}"; do
    if [[ "$app_id" == "$wanted" ]]; then
      return 0
    fi
  done

  return 1
}

configure_vscode_flatpak_permissions() {
  local app_id="com.visualstudio.code"

  flatpak_is_configured "$app_id" || return 0

  if [[ "${WS_DRY_RUN}" != "1" ]] && ! flatpak info "$app_id" >/dev/null 2>&1; then
    return 0
  fi

  log "Allowing VS Code Flatpak to use flatpak-spawn --host for project Distrobox integration."
  run flatpak override --user --talk-name=org.freedesktop.Flatpak "$app_id"
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

flatpaks=()

section "Flatpak setup"
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
  log "No Flatpak applications configured; skipping app install."
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

configure_vscode_flatpak_permissions

log "Flatpak setup complete. Some apps may appear after logging out and back in."
