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
host_project_path="$(find_project_dir_by_normalized_name "$project_name")"
normalized_project="$(normalize_project_name "$project_name")"
box_name="project-${normalized_project}"
project_mount="/work/${normalized_project}"
ai_project_path=""

command_exists distrobox-enter || die "distrobox-enter is not installed."

if ! distrobox_exists "$box_name"; then
  die "Project Distrobox '$box_name' does not exist. Create it with: ws-new <template> ${project_name}"
fi

if [[ -d "$host_project_path" ]] && command_exists readlink; then
  projects_root="$(readlink -f -- "${HOME}/Projects")"
  resolved_project_path="$(readlink -f -- "$host_project_path")"

  case "$resolved_project_path" in
    "$projects_root"/*)
      relative_project_path="${resolved_project_path#"$projects_root"/}"
      ai_project_path="/work/projects/${relative_project_path}"
      ;;
  esac
fi

sync_ai_bin_to_box "$box_name"
if distrobox_exists "claude-code"; then
  if ! sync_ai_bin_to_box "claude-code"; then
    warn "Could not sync AI bin into claude-code; ws-enter will continue without refreshing that tool box."
  fi
fi
if distrobox_exists "codex"; then
  if ! sync_ai_bin_to_box "codex"; then
    warn "Could not sync AI bin into codex; ws-enter will continue without refreshing that tool box."
  fi
fi

exec distrobox-enter --name "$box_name" -- env \
  WS_AI_CLAUDE_BOX="claude-code" \
  WS_AI_CODEX_BOX="codex" \
  WS_AI_PROJECT_ROOT="$ai_project_path" \
  WS_PROJECT_BOX_NAME="$box_name" \
  WS_PROJECT_BOX_ROOT="$project_mount" \
  bash -lc '
    set -euo pipefail

    project_mount="$1"
    ai_bin="${HOME}/.local/share/ws-ai/bin"

    export WS_AI_BIN_DIR="$ai_bin"
    export PATH="${ai_bin}:${PATH}"

    cd "$project_mount" 2>/dev/null || cd "${HOME}"
    exec "${SHELL:-bash}" -l
  ' _ "$project_mount"
