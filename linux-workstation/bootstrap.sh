#!/usr/bin/env bash
# Bootstrap a minimal Ubuntu management host for Flatpak, Podman, Distrobox,
# base task boxes, and project-scoped development environments.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "${SCRIPT_DIR}/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh [--dry-run]

Bootstraps the Ubuntu host in this order:
  1. install-host-packages.sh
  2. install-flatpaks.sh
  3. create-folders.sh
  4. create-base-boxes.sh
  5. install-shell-integration.sh
  6. verify.sh

This script refuses to run as root. It installs only host management tools;
project language stacks belong inside project Distroboxes or devcontainers.
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
      die "Unknown bootstrap option: $1"
      ;;
  esac
done

section "Ubuntu workstation bootstrap"
require_not_root
require_debian_like

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  warn "Dry-run mode is enabled; commands will be printed but not executed."
fi

section "Preparing executable scripts"
run chmod +x \
  "${REPO_ROOT}/bootstrap.sh" \
  "${REPO_ROOT}"/scripts/*.sh \
  "${REPO_ROOT}"/bin/ws-* \
  "${REPO_ROOT}"/boxes/*.sh \
  "${REPO_ROOT}"/templates/project-envs/*.sh

section "Installing host management packages"
bash "${REPO_ROOT}/scripts/install-host-packages.sh"

section "Installing Flatpak desktop applications"
bash "${REPO_ROOT}/scripts/install-flatpaks.sh"

section "Creating workstation folders"
bash "${REPO_ROOT}/scripts/create-folders.sh"

section "Creating base Distroboxes"
bash "${REPO_ROOT}/scripts/create-base-boxes.sh"

section "Installing Bash wrapper commands"
bash "${REPO_ROOT}/scripts/install-shell-integration.sh"

section "Verifying setup"
if [[ "${WS_DRY_RUN}" == "1" ]]; then
  warn "Skipping verify.sh in dry-run mode because setup changes were not applied."
else
  bash "${REPO_ROOT}/scripts/verify.sh"
fi

section "Done"
log "Host stays lean; serious tooling goes into project boxes."
log "Open a new terminal or run 'source ~/.bashrc' to use the ws-* helper commands."
