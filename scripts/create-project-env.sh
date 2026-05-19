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
  rust rust-nightly cpp csharp dotnet java js node python php generic

Options:
  --image <image>          Container image to use. Default: ubuntu:24.04
  --with-devcontainer      Copy matching templates/devcontainer/<template>/ files
  --with-docker            Install Docker/Compose tooling inside the project box
  --with-claude            Install Claude Code inside the project box
  --with-codex             Install Codex CLI inside the project box
  --with-ai                Install both Claude Code and Codex CLI
  --force                  Allow overwriting generated .devcontainer
  --no-ide                 Do not install VS Code in the project box
  --no-template-run        Create the box but skip running the project template
  --dry-run, -n            Print intended changes without applying them

Examples:
  ./scripts/create-project-env.sh rust ExampleProject
  ./scripts/create-project-env.sh dotnet HackJack --with-devcontainer --with-docker
  ./scripts/create-project-env.sh rust AgentProject --with-claude
  ./scripts/create-project-env.sh node CSIT314-TalentMatching
  ./scripts/create-project-env.sh cpp EngineExperiment
EOF
}

normalize_template_name() {
  local raw="$1"
  local lowered

  lowered="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"

  case "$lowered" in
    c++|cpp|cplusplus)
      printf 'cpp\n'
      ;;
    c#|csharp|cs)
      printf 'csharp\n'
      ;;
    js|javascript)
      printf 'js\n'
      ;;
    nightly-rust|rust-nightly)
      printf 'rust-nightly\n'
      ;;
    *)
      printf '%s\n' "$lowered"
      ;;
  esac
}

devcontainer_template_name() {
  local normalized="$1"

  case "$normalized" in
    csharp)
      printf 'dotnet\n'
      ;;
    js)
      printf 'node\n'
      ;;
    rust-nightly)
      printf 'rust\n'
      ;;
    *)
      printf '%s\n' "$normalized"
      ;;
  esac
}

image="ubuntu:24.04"
with_devcontainer=0
install_docker=0
install_claude=0
install_codex=0
force=0
run_template=1
install_vscode=1
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

template="$(normalize_template_name "${1:-}")"
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
    --with-docker)
      install_docker=1
      shift
      ;;
    --with-claude)
      install_claude=1
      shift
      ;;
    --with-codex)
      install_codex=1
      shift
      ;;
    --with-ai)
      install_claude=1
      install_codex=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    --no-ide)
      install_vscode=0
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

[[ "$template" =~ ^[a-z0-9._-]+$ ]] || die "Template name contains unsupported characters after normalization: $template"

template_script="${REPO_ROOT}/templates/project-envs/${template}.sh"
project_baseline_template="${REPO_ROOT}/templates/project-envs/_project-baseline.sh"
docker_template="${REPO_ROOT}/templates/project-envs/_docker.sh"
ai_template="${REPO_ROOT}/templates/project-envs/_ai-tools.sh"
[[ -f "$template_script" ]] || die "Unknown project template '$template'. Expected $template_script"
[[ -f "$project_baseline_template" ]] || die "Missing project baseline template: $project_baseline_template"

if [[ "$install_docker" -eq 1 ]]; then
  [[ -f "$docker_template" ]] || die "Missing Docker template: $docker_template"
fi

if [[ "$install_claude" -eq 1 || "$install_codex" -eq 1 ]]; then
  [[ -f "$ai_template" ]] || die "Missing AI tools template: $ai_template"
fi

normalized_project="$(normalize_project_name "$project_name")"
box_name="project-${normalized_project}"
project_dir="${HOME}/Projects/${project_name}"
box_home="${HOME}/Boxes/projects/${project_name}"
project_mount="/work/${normalized_project}"

if [[ "$with_devcontainer" -eq 1 ]]; then
  devcontainer_template="${REPO_ROOT}/templates/devcontainer/$(devcontainer_template_name "$template")"
  [[ -d "$devcontainer_template" ]] || die "No devcontainer template exists for '$template'."
fi

log "Project: ${project_name}"
log "Distrobox: ${box_name}"
log "Source folder: ${project_dir}"
log "Box home: ${box_home}"
log "Image: ${image}"
if [[ "$install_vscode" -eq 1 ]]; then
  log "IDE: VS Code will be installed inside the project box"
else
  log "IDE: skipped because --no-ide was passed"
fi
if [[ "$install_docker" -eq 1 ]]; then
  log "Container tooling: Docker/Compose will be installed inside the project box"
else
  log "Container tooling: skipped; pass --with-docker to install Docker in this project box"
fi
if [[ "$install_claude" -eq 1 || "$install_codex" -eq 1 ]]; then
  if [[ "$install_claude" -eq 1 && "$install_codex" -eq 1 ]]; then
    log "AI tooling: Claude Code and Codex CLI will be installed inside the project box"
  elif [[ "$install_claude" -eq 1 ]]; then
    log "AI tooling: Claude Code will be installed inside the project box"
  else
    log "AI tooling: Codex CLI will be installed inside the project box"
  fi
else
  log "AI tooling: skipped; pass --with-claude, --with-codex, or --with-ai"
fi

ensure_dir "$project_dir"
ensure_dir "$box_home"
ensure_ai_state_dirs

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
    --volume "${HOME}/Boxes/ai-state:/work/ai-state:rw" \
    --yes
fi

if [[ "$run_template" -eq 1 ]]; then
  log "Running project baseline and '$template' template inside '$box_name'."
  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    log "Would run ${project_baseline_template}, optional add-ons, and ${template_script} inside ${box_name}."
  else
    {
      cat "$project_baseline_template"
      printf '\n'
      if [[ "$install_docker" -eq 1 ]]; then
        cat "$docker_template"
        printf '\n'
      fi
      cat "$template_script"
    } | distrobox-enter --name "$box_name" -- env WS_INSTALL_VSCODE="$install_vscode" bash -s -- "$project_mount" "$project_name"

    if [[ "$install_claude" -eq 1 || "$install_codex" -eq 1 ]]; then
      distrobox-enter --name "$box_name" -- env \
        WS_INSTALL_CLAUDE="$install_claude" \
        WS_INSTALL_CODEX="$install_codex" \
        bash -s -- "$project_mount" "$project_name" < "$ai_template"
    fi
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

if [[ "$install_docker" -eq 1 ]]; then
  cat <<'EOF'

Docker/Compose was requested for this project box. After entering the box, check:
  docker --version
  docker compose version

If group membership changed, exit and re-enter the Distrobox before using Docker.
EOF
fi

if [[ "$install_claude" -eq 1 || "$install_codex" -eq 1 ]]; then
  cat <<'EOF'

AI tools were requested for this project box. After entering the box, check:
EOF
  [[ "$install_claude" -eq 1 ]] && printf '  claude --version\n'
  [[ "$install_codex" -eq 1 ]] && printf '  codex --version\n'
fi
