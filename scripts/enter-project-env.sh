#!/usr/bin/env bash
# Enter a project Distrobox and start in the mounted project directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/enter-project-env.sh <project-name>

Example:
  ./scripts/enter-project-env.sh ExampleProject
EOF
}

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

project_name="$1"
normalized_project="$(normalize_project_name "$project_name")"
box_name="project-${normalized_project}"
project_mount="/work/${normalized_project}"

command_exists distrobox-enter || die "distrobox-enter is not installed."

if ! distrobox_exists "$box_name"; then
  die "Project Distrobox '$box_name' does not exist. Create it with: ws-new <template> ${project_name}"
fi

exec distrobox-enter --name "$box_name" -- bash -lc "cd '${project_mount}' 2>/dev/null || cd \"\${HOME}\"; exec \"\${SHELL:-bash}\" -l"
