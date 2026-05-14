#!/usr/bin/env bash
# Run an AI coding CLI from the shared ai-code Distrobox in a project folder.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-ai-tool.sh <claude|codex|shell> [--dry-run] <project-name> [tool-args...]
  ./scripts/run-ai-tool.sh <claude|codex|shell> [--dry-run] --path <host-project-path> [tool-args...]

Examples:
  ws-claude TerraKit
  ws-codex TerraKit
  ws-ai-shell TerraKit
  ws-claude --path ~/Projects/TerraKit --dangerously-skip-permissions
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
  claude|codex|shell)
    ;;
  *)
    die "Unknown AI tool '$tool'. Expected claude, codex, or shell."
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
  shift 2
else
  project_name="$1"
  host_project_path="$(find_project_dir_by_normalized_name "$project_name")"
  shift
fi

[[ -d "$host_project_path" ]] || die "Project folder does not exist: $host_project_path"

projects_root="$(readlink -f -- "${HOME}/Projects")"
resolved_project_path="$(readlink -f -- "$host_project_path")"

case "$resolved_project_path" in
  "$projects_root"/*)
    relative_project_path="${resolved_project_path#"$projects_root"/}"
    box_project_path="/work/projects/${relative_project_path}"
    ;;
  *)
    die "Project path must be under ${HOME}/Projects so ai-code can see it."
    ;;
esac

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  if [[ "$tool" == "shell" ]]; then
    log "Would enter ai-code at ${box_project_path}."
  else
    log "Would run '${tool}' in ai-code at ${box_project_path}."
  fi
  exit 0
fi

command_exists distrobox-enter || die "distrobox-enter is not installed."

if ! distrobox_exists ai-code; then
  die "Distrobox 'ai-code' does not exist. Run ./bootstrap.sh first."
fi

case "$tool" in
  shell)
    exec distrobox-enter --name ai-code -- bash -lc 'if [ -s "${HOME}/.nvm/nvm.sh" ]; then . "${HOME}/.nvm/nvm.sh"; fi; cd "$1" || exit 1; exec "${SHELL:-bash}" -l' _ "$box_project_path"
    ;;
  claude|codex)
    exec distrobox-enter --name ai-code -- bash -lc 'if [ -s "${HOME}/.nvm/nvm.sh" ]; then . "${HOME}/.nvm/nvm.sh"; fi; cd "$1" || exit 1; shift; exec "$@"' _ "$box_project_path" "$tool" "$@"
    ;;
esac
