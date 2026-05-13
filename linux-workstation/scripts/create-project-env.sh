#!/usr/bin/env bash
# Create one isolated Distrobox per project. Development tooling is installed
# inside that project environment, never directly on the host.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/create-project-env.sh <template> <project-name> [options]

Templates:
  rust dotnet node python php generic

Options:
  --image <image>          Container image to use. Default: ubuntu:24.04
  --with-devcontainer      Copy matching templates/devcontainer/<template>/ files
  --force                  Allow overwriting generated .devcontainer
  --no-template-run        Create the box but skip running the project template
  --dry-run, -n            Print intended changes without applying them

Examples:
  ./scripts/create-project-env.sh rust Terrakit
  ./scripts/create-project-env.sh dotnet HackJack --with-devcontainer
  ./scripts/create-project-env.sh node CSIT314-TalentMatching
EOF
}

image="ubuntu:24.04"
with_devcontainer=0
force=0
run_template=1
template=""
project_name=""

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

template="${1:-}"
project_name="${2:-}"

if [[ -z "$template" || -z "$project_name" ]]; then
  usage
  exit 1
fi

shift 2

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      [[ $# -ge 2 ]] || die "--image requires a value."
      image="$2"
      shift 2
      ;;
    --with-devcontainer)
      with_devcontainer=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    --no-template-run)
      run_template=0
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

section "Project environment creation"

template_script="${REPO_ROOT}/templates/project-envs/${template}.sh"
[[ -f "$template_script" ]] || die "Unknown project template '$template'. Expected $template_script"

normalized_project="$(normalize_project_name "$project_name")"
box_name="project-${normalized_project}"
project_dir="${HOME}/Projects/${project_name}"
box_home="${HOME}/Boxes/projects/${project_name}"
project_mount="/work/${normalized_project}"

if [[ "$with_devcontainer" -eq 1 ]]; then
  devcontainer_template="${REPO_ROOT}/templates/devcontainer/${template}"
  [[ -d "$devcontainer_template" ]] || die "No devcontainer template exists for '$template'."
fi

log "Project: ${project_name}"
log "Distrobox: ${box_name}"
log "Source folder: ${project_dir}"
log "Box home: ${box_home}"
log "Image: ${image}"

ensure_dir "$project_dir"
ensure_dir "$box_home"

if ! command_exists distrobox-create && [[ "${WS_DRY_RUN}" != "1" ]]; then
  die "distrobox-create is not installed. Run ./bootstrap.sh first."
fi

if ! command_exists distrobox-enter && [[ "${WS_DRY_RUN}" != "1" ]]; then
  die "distrobox-enter is not installed. Run ./bootstrap.sh first."
fi

if distrobox_exists "$box_name"; then
  log "Distrobox already exists: $box_name"
else
  log "Creating Distrobox '$box_name'."
  run distrobox-create \
    --name "$box_name" \
    --image "$image" \
    --home "$box_home" \
    --volume "${project_dir}:${project_mount}:rw" \
    --yes
fi

if [[ "$run_template" -eq 1 ]]; then
  log "Running template '$template' inside '$box_name'."
  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    log "Would run ${template_script} inside ${box_name}."
  else
    distrobox-enter --name "$box_name" -- bash -s -- "$project_mount" "$project_name" < "$template_script"
  fi
else
  log "Skipping template run because --no-template-run was passed."
fi

log "Ensuring ~/project points at ${project_mount} inside the box."
if [[ "${WS_DRY_RUN}" == "1" ]]; then
  log "Would create ~/project symlink inside ${box_name}."
else
  distrobox-enter --name "$box_name" -- bash -lc "mkdir -p /work && ln -sfn '${project_mount}' \"\${HOME}/project\""
fi

if [[ "$with_devcontainer" -eq 1 ]]; then
  devcontainer_dir="${project_dir}/.devcontainer"

  if [[ -e "$devcontainer_dir" && "$force" -ne 1 ]]; then
    warn "Not overwriting existing ${devcontainer_dir}. Pass --force to replace it."
  else
    if [[ "$force" -eq 1 ]]; then
      safe_remove_dir_under "$devcontainer_dir" "$project_dir"
    fi

    log "Copying devcontainer template to ${devcontainer_dir}."
    run mkdir -p "$devcontainer_dir"
    run cp -a "${devcontainer_template}/." "$devcontainer_dir/"
  fi
fi

cat <<EOF

Project environment is ready.

Enter it with:
  ws-enter ${project_name}

Or without wrappers:
  distrobox-enter --name ${box_name}

Inside the box, the project folder is mounted at:
  ${project_mount}

A convenience symlink is also created at:
  ~/project
EOF
