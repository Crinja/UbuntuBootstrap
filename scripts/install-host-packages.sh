#!/usr/bin/env bash
# Install only host-level management packages. Language runtimes and
# project-specific CLIs belong inside project Distroboxes or devcontainers.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install-host-packages.sh [--dry-run]

Installs packages listed in config/host-packages.txt with apt.
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

section "Host package install"
require_debian_like
if ! command_exists apt-get; then
  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    warn "apt-get was not found, but continuing because dry-run mode is enabled."
  else
    die "apt-get was not found."
  fi
fi

mapfile -t packages < <(read_config_lines "${REPO_ROOT}/config/host-packages.txt")

if [[ "${#packages[@]}" -eq 0 ]]; then
  warn "No host packages configured."
  exit 0
fi

log "Installing ${#packages[@]} management/system packages from config/host-packages.txt."
sudo_run apt-get update
sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"

log "Host package install complete."
