#!/usr/bin/env bash
# Run an AI coding CLI from inside a project Distrobox shell.
#
# The project box gets a small ws-ai bin directory on PATH. The visible
# commands, such as claude and codex, live there and call back into the real AI
# tool boxes while routing shell execution through the project box.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-ai-tool.sh <claude|codex> [options] <project-name> [tool-args...]
  ./scripts/run-ai-tool.sh <claude|codex> [options] --path <host-project-path> [tool-args...]

Options:
  --dry-run, -n     Print what would happen without running it.

Examples:
  ws-claude ExampleProject
  ws-codex ExampleProject
  ws-claude ExampleProject --help
EOF
}

if [[ $# -lt 1 || "$1" == "--help" || "$1" == "-h" ]]; then
  usage
  if [[ $# -lt 1 ]]; then
    exit 1
  fi
  exit 0
fi

tool="$1"
shift

case "$tool" in
  claude)
    ai_box_name="claude-code"
    ;;
  codex)
    ai_box_name="codex"
    ;;
  *)
    die "Unknown AI tool '$tool'. Expected claude or codex."
    ;;
esac

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
      break
      ;;
  esac
done

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

if [[ "$1" == "--path" ]]; then
  [[ $# -ge 2 ]] || die "--path requires a host project path."
  host_project_path="$(expand_user_path "$2")"
  project_name="$(basename "$host_project_path")"
  shift 2
else
  project_name="$1"
  host_project_path="$(find_project_dir_by_normalized_name "$project_name")"
  shift
fi

[[ -d "$host_project_path" ]] || die "Project folder does not exist: $host_project_path"

command_exists readlink || die "readlink is required."

projects_root="$(readlink -f -- "${HOME}/Projects")"
resolved_project_path="$(readlink -f -- "$host_project_path")"

case "$resolved_project_path" in
  "$projects_root"/*)
    relative_project_path="${resolved_project_path#"$projects_root"/}"
    ai_project_path="/work/projects/${relative_project_path}"
    ;;
  *)
    die "Project path must be under ${HOME}/Projects so the AI tool boxes can see it."
    ;;
esac

normalized_project="$(normalize_project_name "$project_name")"
project_box_name="project-${normalized_project}"
project_box_path="/work/${normalized_project}"

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  log "Would sync AI bin into ${project_box_name} and ${ai_box_name}."
  log "Would enter ${project_box_name} at ${project_box_path} with ~/.local/share/ws-ai/bin on PATH."
  log "Would run '${tool}' from ${ai_box_name}; shell commands route back to ${project_box_name}."
  exit 0
fi

command_exists distrobox-enter || die "distrobox-enter is not installed."
command_exists tar || die "tar is required."

if ! distrobox_exists "$project_box_name"; then
  die "Project Distrobox '${project_box_name}' does not exist. Create it with: ws-new <template> ${project_name}"
fi

if ! distrobox_exists "$ai_box_name"; then
  die "Distrobox '${ai_box_name}' does not exist. Run ./bootstrap.sh first."
fi

sync_ai_bin_to_box "$project_box_name"
sync_ai_bin_to_box "$ai_box_name"

exec distrobox-enter --name "$project_box_name" -- env \
  WS_AI_CLAUDE_BOX="claude-code" \
  WS_AI_CODEX_BOX="codex" \
  WS_AI_PROJECT_ROOT="$ai_project_path" \
  WS_PROJECT_BOX_NAME="$project_box_name" \
  WS_PROJECT_BOX_ROOT="$project_box_path" \
  bash -lc '
    set -euo pipefail

    project_dir="$1"
    tool_name="$2"
    shift 2

    ai_bin="${HOME}/.local/share/ws-ai/bin"
    export WS_AI_BIN_DIR="$ai_bin"
    export PATH="${ai_bin}:${PATH}"

    cd "$project_dir" || exit 1
    exec "$tool_name" "$@"
  ' _ "$project_box_path" "$tool" "$@"
