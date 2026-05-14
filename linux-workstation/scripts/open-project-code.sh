#!/usr/bin/env bash
# Launch VS Code from a Distrobox, not from the host.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/open-project-code.sh <project-name> [code-args...]
  ./scripts/open-project-code.sh --base [code-args...]
  ./scripts/open-project-code.sh --box <distrobox-name> [code-args...]

Examples:
  ws-code Terrakit
  ws-code Terrakit .
  ws-code --base
  ws-code --box experimental ~/Scratch

VS Code must be installed inside the selected Distrobox.
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  usage
  exit 0
fi

box_name=""
default_target=""

case "$1" in
  --base)
    box_name="dev-base"
    default_target="${HOME}"
    shift
    ;;
  --box)
    [[ $# -ge 2 ]] || die "--box requires a Distrobox name."
    box_name="$2"
    default_target="${HOME}"
    shift 2
    ;;
  *)
    project_name="$1"
    normalized_project="$(normalize_project_name "$project_name")"
    box_name="project-${normalized_project}"
    default_target="/work/${normalized_project}"
    shift
    ;;
esac

command_exists distrobox-enter || die "distrobox-enter is not installed."

if ! distrobox_exists "$box_name"; then
  die "Distrobox '$box_name' does not exist."
fi

if [[ $# -eq 0 ]]; then
  set -- "$default_target"
fi

exec distrobox-enter --name "$box_name" -- code "$@"
