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
  --with-devcontainer      Copy matching devcontainer files and enable host Podman
  --with-podman            Enable VS Code Dev Containers with host Podman
  --with-claude            Install Claude Code inside the project box
  --with-codex             Install Codex CLI inside the project box
  --with-ai                Install both Claude Code and Codex CLI
  --force                  Allow overwriting generated .devcontainer
  --no-ide                 Deprecated no-op; VS Code is launched as a Flatpak
  --no-template-run        Create the box but skip running the project template
  --dry-run, -n            Print intended changes without applying them

Examples:
  ./scripts/create-project-env.sh rust ExampleProject
  ./scripts/create-project-env.sh dotnet ApiExample --with-devcontainer
  ./scripts/create-project-env.sh rust AgentProject --with-claude
  ./scripts/create-project-env.sh node WebExample
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

enable_vscode_podman_bridge() {
  local marker_path="$1"

  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    log "Would enable VS Code Dev Containers host Podman bridge at ${marker_path}."
    return 0
  fi

  mkdir -p "$(dirname "$marker_path")"
  cat >"$marker_path" <<'EOF'
# Created by ws-new --with-devcontainer or --with-podman.
# When this file exists, ws-code writes project-local Dev Containers settings
# that run container commands through host rootless Podman.
EOF
}

image="ubuntu:24.04"
with_devcontainer=0
enable_podman_devcontainers=0
install_claude=0
install_codex=0
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
      enable_podman_devcontainers=1
      shift
      ;;
    --with-podman)
      enable_podman_devcontainers=1
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
      warn "--no-ide is deprecated and no longer needed; VS Code is not installed inside project boxes."
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
ai_template="${REPO_ROOT}/templates/project-envs/_ai-tools.sh"
[[ -f "$template_script" ]] || die "Unknown project template '$template'. Expected $template_script"
[[ -f "$project_baseline_template" ]] || die "Missing project baseline template: $project_baseline_template"

if [[ "$install_claude" -eq 1 || "$install_codex" -eq 1 ]]; then
  [[ -f "$ai_template" ]] || die "Missing AI tools template: $ai_template"
fi

normalized_project="$(normalize_project_name "$project_name")"
box_name="project-${normalized_project}"
project_dir="${HOME}/Projects/${project_name}"
box_home="${HOME}/Boxes/projects/${project_name}"
project_mount="/work/${normalized_project}"
vscode_podman_bridge_marker="${box_home}/.vscode-flatpak/enable-host-podman"

if [[ "$with_devcontainer" -eq 1 ]]; then
  devcontainer_template="${REPO_ROOT}/templates/devcontainer/$(devcontainer_template_name "$template")"
  [[ -d "$devcontainer_template" ]] || die "No devcontainer template exists for '$template'."
fi

log "Project: ${project_name}"
log "Distrobox: ${box_name}"
log "Source folder: ${project_dir}"
log "Box home: ${box_home}"
log "Image: ${image}"
log "Editor: use ws-code ${project_name} to launch the VS Code Flatpak with project-specific Code state"
if [[ "$enable_podman_devcontainers" -eq 1 ]]; then
  log "Dev Containers: VS Code will use host rootless Podman for this project"
else
  log "Dev Containers: skipped; pass --with-devcontainer or --with-podman to enable host Podman"
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

if ! command_exists distrobox-create && [[ "${WS_DRY_RUN}" != "1" ]]; then
  die "distrobox-create is not installed. Run ./bootstrap.sh first."
fi

if ! command_exists distrobox-enter && [[ "${WS_DRY_RUN}" != "1" ]]; then
  die "distrobox-enter is not installed. Run ./bootstrap.sh first."
fi

if distrobox_exists "$box_name"; then
  log "Distrobox already exists: $box_name"
else
  create_args=(
    --name "$box_name"
    --image "$image"
    --home "$box_home"
    --volume "${project_dir}:${project_mount}:rw"
    --yes
  )

  log "Creating Distrobox '$box_name'."
  run distrobox-create "${create_args[@]}"
fi

if [[ "$run_template" -eq 1 ]]; then
  log "Running project baseline and '$template' template inside '$box_name'."
  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    log "Would run ${project_baseline_template}, optional add-ons, and ${template_script} inside ${box_name}."
  else
    {
      cat "$project_baseline_template"
      printf '\n'
      cat "$template_script"
    } | distrobox-enter --name "$box_name" -- bash -s -- "$project_mount" "$project_name"

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

if [[ "$enable_podman_devcontainers" -eq 1 ]]; then
  enable_vscode_podman_bridge "$vscode_podman_bridge_marker"
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

Open it in VS Code with:
  ws-code ${project_name}

Or without wrappers:
  distrobox-enter --name ${box_name}

Inside the box, the project folder is mounted at:
  ${project_mount}

A convenience symlink is also created at:
  ~/project
EOF

if [[ "$enable_podman_devcontainers" -eq 1 ]]; then
  cat <<EOF

Dev Containers were enabled for this project.

VS Code will use host rootless Podman through project-local settings.
Check the host runtime with:
  podman info

The next ws-code launch will install the Dev Containers extension into this
project's VS Code extension directory and configure project-local Podman
settings for it.
EOF
fi

if [[ "$install_claude" -eq 1 || "$install_codex" -eq 1 ]]; then
  cat <<'EOF'

AI tools were requested for this project box. After entering the box, check:
EOF
  if [[ "$install_claude" -eq 1 ]]; then
    printf '  claude --version\n'
  fi
  if [[ "$install_codex" -eq 1 ]]; then
    printf '  codex --version\n'
  fi
fi
