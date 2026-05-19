#!/usr/bin/env bash
# Add Claude Code and/or Codex CLI to an existing project Distrobox.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/add-project-ai-tools.sh <project-name> [--claude] [--codex] [--all] [--dry-run]
  ./scripts/add-project-ai-tools.sh <project-name> claude|codex|all

Examples:
  ws-ai-add ExampleProject --claude
  ws-ai-add ExampleProject --codex
  ws-ai-add ExampleProject --all
EOF
}

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

install_claude=0
install_codex=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude|claude)
      install_claude=1
      shift
      ;;
    --codex|codex)
      install_codex=1
      shift
      ;;
    --all|all|both|--with-ai)
      install_claude=1
      install_codex=1
      shift
      ;;
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

if [[ "$install_claude" -ne 1 && "$install_codex" -ne 1 ]]; then
  die "Choose at least one AI tool: --claude, --codex, or --all."
fi

section "Project AI tooling"

normalized_project="$(normalize_project_name "$project_name")"
box_name="project-${normalized_project}"
project_mount="/work/${normalized_project}"
ai_template="${REPO_ROOT}/templates/project-envs/_ai-tools.sh"

[[ -f "$ai_template" ]] || die "Missing AI tools template: $ai_template"

if ! command_exists distrobox-enter && [[ "${WS_DRY_RUN}" != "1" ]]; then
  die "distrobox-enter is not installed. Run ./bootstrap.sh first."
fi

if ! distrobox_exists "$box_name" && [[ "${WS_DRY_RUN}" != "1" ]]; then
  die "Project Distrobox '${box_name}' does not exist. Create it with: ws-new <template> ${project_name}"
fi

ensure_ai_state_dirs

log "Project: ${project_name}"
log "Distrobox: ${box_name}"
[[ "$install_claude" -eq 1 ]] && log "Will install Claude Code inside ${box_name}."
[[ "$install_codex" -eq 1 ]] && log "Will install Codex CLI inside ${box_name}."

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  log "Would require project Distrobox: ${box_name}."
  log "Would run ${ai_template} inside ${box_name}."
  exit 0
fi

distrobox-enter --name "$box_name" -- env \
  WS_INSTALL_CLAUDE="$install_claude" \
  WS_INSTALL_CODEX="$install_codex" \
  bash -s -- "$project_mount" "$project_name" < "$ai_template"

cat <<EOF

AI tooling is ready for ${project_name}.

Enter the project and run:
  ws-enter ${project_name}
EOF

if [[ "$install_claude" -eq 1 ]]; then
  printf '  claude\n'
fi
if [[ "$install_codex" -eq 1 ]]; then
  printf '  codex\n'
fi
