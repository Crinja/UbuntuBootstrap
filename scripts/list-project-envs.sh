#!/usr/bin/env bash
# List project-scoped Distrobox environments.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/list-project-envs.sh

Shows project name, Distrobox name, source path, and box home path.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

section "Project environments"

projects_root="${HOME}/Boxes/projects"

if [[ ! -d "$projects_root" ]]; then
  log "No project box homes found at ${projects_root}."
  exit 0
fi

printf '%-28s %-34s %-42s %s\n' "PROJECT" "DISTROBOX" "PROJECT PATH" "BOX HOME"
printf '%-28s %-34s %-42s %s\n' "-------" "---------" "------------" "--------"

found=0

while IFS= read -r -d '' home_dir; do
  project_name="$(basename "$home_dir")"
  normalized_project="$(normalize_project_name "$project_name")"
  box_name="project-${normalized_project}"
  project_dir="${HOME}/Projects/${project_name}"

  printf '%-28s %-34s %-42s %s\n' "$project_name" "$box_name" "$project_dir" "$home_dir"
  found=1
done < <(find "$projects_root" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

if [[ "$found" -eq 0 ]]; then
  log "No project environments found."
fi
