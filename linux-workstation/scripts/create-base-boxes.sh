#!/usr/bin/env bash
# Create broad task Distroboxes. These are not development stacks.
# Custom --home paths reduce dotfile/config contamination on the host, but
# Distrobox is a workflow and contamination-control tool, not a hard security
# boundary. Use a VM for genuinely untrusted software.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/create-base-boxes.sh [--dry-run]

Creates base boxes from config/base-boxes.conf:
  name|image|home
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

section "Base Distrobox creation"
if ! command_exists distrobox-create; then
  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    warn "distrobox-create is not installed, but continuing because dry-run mode is enabled."
  else
    die "distrobox-create is not installed. Run install-host-packages.sh first."
  fi
fi

config_file="${REPO_ROOT}/config/base-boxes.conf"

while IFS='|' read -r name image home_path; do
  [[ -n "${name:-}" ]] || continue
  [[ -n "${image:-}" ]] || die "Missing image for base box '$name'."
  [[ -n "${home_path:-}" ]] || die "Missing home path for base box '$name'."

  home_path="$(expand_user_path "$home_path")"

  ensure_dir "$home_path"

  if distrobox_exists "$name"; then
    log "Base box already exists: $name"
    continue
  fi

  log "Creating base box '$name' from '$image' with home '$home_path'."
  run distrobox-create --name "$name" --image "$image" --home "$home_path" --yes
done < <(read_config_lines "$config_file")

log "Base Distrobox creation complete. Boxes are not entered automatically."
