#!/usr/bin/env bash
# Remove a project Distrobox after confirmation. Source files are preserved by
# default; box home deletion is a separate explicit confirmation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/remove-project-env.sh <project-name> [--yes]

Removes only the Distrobox by default. It does not delete:
  ~/Projects/<project-name>

It asks separately before deleting:
  ~/Boxes/projects/<project-name>
EOF
}

project_name=""

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

project_name="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
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

section "Remove project environment"

normalized_project="$(normalize_project_name "$project_name")"
box_name="project-${normalized_project}"
project_dir="$(find_project_dir_by_normalized_name "$project_name")"
box_home="$(find_project_home_by_normalized_name "$project_name")"

log "Distrobox: ${box_name}"
log "Project source folder will be preserved: ${project_dir}"
log "Box home: ${box_home}"

command_exists distrobox-rm || die "distrobox-rm is not installed."

if distrobox_exists "$box_name"; then
  if confirm "Remove Distrobox '${box_name}'?"; then
    run distrobox-rm --name "$box_name" --force
  else
    log "Distrobox removal cancelled."
  fi
else
  log "Distrobox does not exist: $box_name"
fi

if [[ -d "$box_home" ]]; then
  if confirm "Also delete box home '${box_home}'? Project files remain untouched."; then
    safe_remove_dir_under "$box_home" "${HOME}/Boxes/projects"
  else
    log "Preserved box home: $box_home"
  fi
else
  log "No box home found at: $box_home"
fi

log "Preserved project source folder: $project_dir"
