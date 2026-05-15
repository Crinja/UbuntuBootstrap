#!/usr/bin/env bash
# Run an AI coding CLI from ai-code while exposing project Distrobox tooling.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-ai-tool.sh <claude|codex|shell> [options] <project-name> [tool-args...]
  ./scripts/run-ai-tool.sh <claude|codex|shell> [options] --path <host-project-path> [tool-args...]

Options:
  --no-tool-bridge  Do not expose project Distrobox SDK tools to ai-code.
  --dry-run, -n     Print what would happen without running it.

Examples:
  ws-claude TerraKit
  ws-codex TerraKit
  ws-ai-shell TerraKit
  ws-claude --no-tool-bridge TerraKit
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
tool_bridge=1

case "$tool" in
  claude|codex|shell)
    ;;
  *)
    die "Unknown AI tool '$tool'. Expected claude, codex, or shell."
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-tool-bridge)
      tool_bridge=0
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
    die "Project path must be under ${HOME}/Projects so ai-code can see it."
    ;;
esac

normalized_project="$(normalize_project_name "$project_name")"
project_box_name="project-${normalized_project}"
project_box_path="/work/${normalized_project}"
bridge_tools="${WS_AI_BRIDGE_TOOLS:-cargo rustc rustup node npm npx pnpm yarn bun deno python python3 pip pip3 uv dotnet java javac jar mvn gradle gradlew gcc g++ cc c++ clang clang++ cmake make ninja pkg-config php composer go docker podman docker-compose}"
bridge_env_path=""

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  if [[ "$tool_bridge" -eq 1 ]]; then
    log "Would expose tools from ${project_box_name}:${project_box_path} inside ai-code."
  fi

  if [[ "$tool" == "shell" ]]; then
    log "Would enter ai-code at ${ai_project_path}."
  else
    log "Would run '${tool}' in ai-code at ${ai_project_path}."
  fi
  exit 0
fi

command_exists distrobox-enter || die "distrobox-enter is not installed."

if ! distrobox_exists ai-code; then
  die "Distrobox 'ai-code' does not exist. Run ./bootstrap.sh first."
fi

source_nvm='
if [ -s "${HOME}/.nvm/nvm.sh" ]; then
  . "${HOME}/.nvm/nvm.sh"
  nvm use default --silent >/dev/null 2>&1 || nvm use --lts --silent >/dev/null 2>&1 || true
fi
'

prepare_tool_bridge() {
  if ! distrobox_exists "$project_box_name"; then
    die "Project Distrobox '${project_box_name}' does not exist. Create it with: ws-new <template> ${project_name}"
  fi

  local bridge_output

  bridge_output="$(
    distrobox-enter --name ai-code -- bash -s -- \
      "$project_box_name" \
      "$ai_project_path" \
      "$project_box_path" \
      "$bridge_tools" <<'EOF'
set -euo pipefail

project_box_name="$1"
ai_project_path="$2"
project_box_path="$3"
bridge_tools="$4"

bridge_root="${HOME}/.local/share/ws-ai-tool-bridge/${project_box_name}"
bridge_bin="${bridge_root}/bin"
bridge_env="${bridge_root}/env"
shim="${bridge_bin}/.ws-project-tool"

mkdir -p "$bridge_bin"

cat >"$shim" <<'SHIM'
#!/usr/bin/env bash
set -euo pipefail

command_name="$(basename "$0")"

if ! command -v distrobox-host-exec >/dev/null 2>&1; then
  printf 'ERROR: distrobox-host-exec is not available inside ai-code; cannot bridge %s into the project box.\n' "$command_name" >&2
  exit 127
fi

: "${WS_PROJECT_BOX_NAME:?}"
: "${WS_AI_PROJECT_ROOT:?}"
: "${WS_PROJECT_BOX_ROOT:?}"

current_dir="$(pwd)"

case "$current_dir" in
  "$WS_AI_PROJECT_ROOT")
    project_dir="$WS_PROJECT_BOX_ROOT"
    ;;
  "$WS_AI_PROJECT_ROOT"/*)
    relative_dir="${current_dir#"$WS_AI_PROJECT_ROOT"/}"
    project_dir="${WS_PROJECT_BOX_ROOT}/${relative_dir}"
    ;;
  *)
    project_dir="$WS_PROJECT_BOX_ROOT"
    ;;
esac

exec distrobox-host-exec distrobox-enter --name "$WS_PROJECT_BOX_NAME" -- \
  bash -lc '
    if [ -f "${HOME}/.cargo/env" ]; then
      . "${HOME}/.cargo/env"
    fi
    export NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
    if [ -s "${NVM_DIR}/nvm.sh" ]; then
      . "${NVM_DIR}/nvm.sh"
      nvm use default --silent >/dev/null 2>&1 || nvm use --lts --silent >/dev/null 2>&1 || true
    fi
    if [ -d "${HOME}/.local/bin" ]; then
      PATH="${HOME}/.local/bin:${PATH}"
      export PATH
    fi
    cd "$1" || exit 1
    shift
    exec "$@"
  ' _ "$project_dir" "$command_name" "$@"
SHIM

cat >"${bridge_bin}/ws-project-exec" <<'PROJECT_EXEC'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  printf 'Usage: ws-project-exec <command> [args...]\n' >&2
  exit 2
fi

if ! command -v distrobox-host-exec >/dev/null 2>&1; then
  printf 'ERROR: distrobox-host-exec is not available inside ai-code; cannot run command in the project box.\n' >&2
  exit 127
fi

: "${WS_PROJECT_BOX_NAME:?}"
: "${WS_AI_PROJECT_ROOT:?}"
: "${WS_PROJECT_BOX_ROOT:?}"

current_dir="$(pwd)"

case "$current_dir" in
  "$WS_AI_PROJECT_ROOT")
    project_dir="$WS_PROJECT_BOX_ROOT"
    ;;
  "$WS_AI_PROJECT_ROOT"/*)
    relative_dir="${current_dir#"$WS_AI_PROJECT_ROOT"/}"
    project_dir="${WS_PROJECT_BOX_ROOT}/${relative_dir}"
    ;;
  *)
    project_dir="$WS_PROJECT_BOX_ROOT"
    ;;
esac

exec distrobox-host-exec distrobox-enter --name "$WS_PROJECT_BOX_NAME" -- \
  bash -lc '
    if [ -f "${HOME}/.cargo/env" ]; then
      . "${HOME}/.cargo/env"
    fi
    export NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
    if [ -s "${NVM_DIR}/nvm.sh" ]; then
      . "${NVM_DIR}/nvm.sh"
      nvm use default --silent >/dev/null 2>&1 || nvm use --lts --silent >/dev/null 2>&1 || true
    fi
    if [ -d "${HOME}/.local/bin" ]; then
      PATH="${HOME}/.local/bin:${PATH}"
      export PATH
    fi
    cd "$1" || exit 1
    shift
    exec "$@"
  ' _ "$project_dir" "$@"
PROJECT_EXEC

cat >"${bridge_bin}/ws-project-shell" <<'PROJECT_SHELL'
#!/usr/bin/env bash
set -euo pipefail

if ! command -v distrobox-host-exec >/dev/null 2>&1; then
  printf 'ERROR: distrobox-host-exec is not available inside ai-code; cannot enter the project box.\n' >&2
  exit 127
fi

: "${WS_PROJECT_BOX_NAME:?}"
: "${WS_AI_PROJECT_ROOT:?}"
: "${WS_PROJECT_BOX_ROOT:?}"

current_dir="$(pwd)"

case "$current_dir" in
  "$WS_AI_PROJECT_ROOT")
    project_dir="$WS_PROJECT_BOX_ROOT"
    ;;
  "$WS_AI_PROJECT_ROOT"/*)
    relative_dir="${current_dir#"$WS_AI_PROJECT_ROOT"/}"
    project_dir="${WS_PROJECT_BOX_ROOT}/${relative_dir}"
    ;;
  *)
    project_dir="$WS_PROJECT_BOX_ROOT"
    ;;
esac

exec distrobox-host-exec distrobox-enter --name "$WS_PROJECT_BOX_NAME" -- \
  bash -lc '
    if [ -f "${HOME}/.cargo/env" ]; then
      . "${HOME}/.cargo/env"
    fi
    export NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"
    if [ -s "${NVM_DIR}/nvm.sh" ]; then
      . "${NVM_DIR}/nvm.sh"
      nvm use default --silent >/dev/null 2>&1 || nvm use --lts --silent >/dev/null 2>&1 || true
    fi
    if [ -d "${HOME}/.local/bin" ]; then
      PATH="${HOME}/.local/bin:${PATH}"
      export PATH
    fi
    cd "$1" || exit 1
    exec "${SHELL:-bash}"
  ' _ "$project_dir"
PROJECT_SHELL

cat >"${bridge_bin}/ws-project-apt-install" <<'PROJECT_APT_INSTALL'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  printf 'Usage: ws-project-apt-install <apt-package> [apt-package...]\n' >&2
  exit 2
fi

if ! command -v distrobox-host-exec >/dev/null 2>&1; then
  printf 'ERROR: distrobox-host-exec is not available inside ai-code; cannot install packages in the project box.\n' >&2
  exit 127
fi

: "${WS_PROJECT_BOX_NAME:?}"

printf 'Installing apt package(s) inside %s only: %s\n' "$WS_PROJECT_BOX_NAME" "$*" >&2

exec distrobox-host-exec distrobox-enter --name "$WS_PROJECT_BOX_NAME" -- \
  bash -lc '
    sudo apt-get update
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  ' _ "$@"
PROJECT_APT_INSTALL

chmod +x "$shim"
chmod +x "${bridge_bin}/ws-project-exec" "${bridge_bin}/ws-project-shell" "${bridge_bin}/ws-project-apt-install"

for tool in $bridge_tools; do
  ln -sfn ".ws-project-tool" "${bridge_bin}/${tool}"
done

{
  printf 'export WS_PROJECT_BOX_NAME=%q\n' "$project_box_name"
  printf 'export WS_AI_PROJECT_ROOT=%q\n' "$ai_project_path"
  printf 'export WS_PROJECT_BOX_ROOT=%q\n' "$project_box_path"
  printf 'export WS_AI_TOOL_BRIDGE=1\n'
  printf 'export PATH=%q:${PATH}\n' "$bridge_bin"
} >"$bridge_env"

printf '__WS_BRIDGE_ENV__ %s\n' "$bridge_env"
EOF
  )"

  bridge_env_path="$(
    printf '%s\n' "$bridge_output" |
      awk '/^__WS_BRIDGE_ENV__ / { sub(/^__WS_BRIDGE_ENV__ /, ""); value=$0 } END { if (value != "") print value }'
  )"

  [[ -n "$bridge_env_path" ]] || die "Could not prepare the AI tool bridge inside ai-code."
}

if [[ "$tool_bridge" -eq 1 ]]; then
  prepare_tool_bridge
fi

case "$tool" in
  shell)
    exec distrobox-enter --name ai-code -- bash -lc "${source_nvm}"'
      if [ -n "$1" ] && [ -f "$1" ]; then
        . "$1"
      fi
      cd "$2" || exit 1
      exec "${SHELL:-bash}"
    ' _ "$bridge_env_path" "$ai_project_path"
    ;;
  claude|codex)
    exec distrobox-enter --name ai-code -- bash -lc "${source_nvm}"'
      if [ -n "$1" ] && [ -f "$1" ]; then
        . "$1"
      fi
      cd "$2" || exit 1
      shift 2
      if ! command -v "$1" >/dev/null 2>&1; then
        printf "ERROR: %s was not found inside ai-code. Run: ws-ai-setup\n" "$1" >&2
        exit 127
      fi
      exec "$@"
    ' _ "$bridge_env_path" "$ai_project_path" "$tool" "$@"
    ;;
esac
