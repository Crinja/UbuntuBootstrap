#!/usr/bin/env bash
# Run an AI coding CLI from a project Distrobox shell.
#
# The AI CLI and auth state live in a dedicated tool box. The working shell
# lives in the project box, so project commands naturally use that project's
# SDKs, PATH, services, and custom home.

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
launcher_bin=""

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  log "Would prepare '${tool}' launcher inside ${project_box_name}."
  log "Would enter ${project_box_name} at ${project_box_path}."
  log "Would run '${tool}' from ${ai_box_name} with project shell routing enabled."
  exit 0
fi

command_exists distrobox-enter || die "distrobox-enter is not installed."

if ! distrobox_exists "$project_box_name"; then
  die "Project Distrobox '${project_box_name}' does not exist. Create it with: ws-new <template> ${project_name}"
fi

if ! distrobox_exists "$ai_box_name"; then
  die "Distrobox '${ai_box_name}' does not exist. Run ./bootstrap.sh first."
fi

prepare_project_launcher() {
  local launcher_output

  launcher_output="$(
    distrobox-enter --name "$project_box_name" -- bash -s -- \
      "$tool" \
      "$ai_box_name" \
      "$ai_project_path" \
      "$project_box_name" \
      "$project_box_path" <<'PROJECT_LAUNCHER_SETUP'
set -euo pipefail

tool_name="$1"
ai_box_name="$2"
ai_project_root="$3"
project_box_name="$4"
project_box_root="$5"

launcher_root="${HOME}/.local/share/ws-ai-launchers/${tool_name}/${project_box_name}"
launcher_bin="${launcher_root}/bin"
launcher="${launcher_bin}/${tool_name}"

mkdir -p "$launcher_bin"

{
  printf '#!/usr/bin/env bash\n'
  printf 'set -euo pipefail\n\n'
  printf 'WS_AI_BOX_NAME=%q\n' "$ai_box_name"
  printf 'WS_AI_TOOL_NAME=%q\n' "$tool_name"
  printf 'WS_AI_PROJECT_ROOT=%q\n' "$ai_project_root"
  printf 'WS_PROJECT_BOX_NAME=%q\n' "$project_box_name"
  printf 'WS_PROJECT_BOX_ROOT=%q\n\n' "$project_box_root"
  cat <<'LAUNCHER_BODY'
if ! command -v distrobox-host-exec >/dev/null 2>&1; then
  printf 'ERROR: distrobox-host-exec is not available inside the project box; cannot launch %s from %s.\n' "$WS_AI_TOOL_NAME" "$WS_AI_BOX_NAME" >&2
  exit 127
fi

current_dir="$(pwd)"

case "$current_dir" in
  "$WS_PROJECT_BOX_ROOT")
    ai_dir="$WS_AI_PROJECT_ROOT"
    ;;
  "$WS_PROJECT_BOX_ROOT"/*)
    relative_dir="${current_dir#"$WS_PROJECT_BOX_ROOT"/}"
    ai_dir="${WS_AI_PROJECT_ROOT}/${relative_dir}"
    ;;
  *)
    ai_dir="$WS_AI_PROJECT_ROOT"
    ;;
esac

exec distrobox-host-exec distrobox-enter --name "$WS_AI_BOX_NAME" -- env \
  -u BASH_ENV \
  -u ENV \
  WS_AI_TOOL_NAME="$WS_AI_TOOL_NAME" \
  WS_AI_START_DIR="$ai_dir" \
  WS_AI_PROJECT_ROOT="$WS_AI_PROJECT_ROOT" \
  WS_PROJECT_BOX_NAME="$WS_PROJECT_BOX_NAME" \
  WS_PROJECT_BOX_ROOT="$WS_PROJECT_BOX_ROOT" \
  bash -s -- "$@" <<'AI_RUNNER'
set -euo pipefail

tool_name="${WS_AI_TOOL_NAME:?}"
start_dir="${WS_AI_START_DIR:?}"
ai_project_root="${WS_AI_PROJECT_ROOT:?}"
project_box_name="${WS_PROJECT_BOX_NAME:?}"
project_box_root="${WS_PROJECT_BOX_ROOT:?}"

if [ -s "${HOME}/.nvm/nvm.sh" ]; then
  . "${HOME}/.nvm/nvm.sh"
  nvm use default --silent >/dev/null 2>&1 || nvm use --lts --silent >/dev/null 2>&1 || true
fi

if ! tool_path="$(command -v "$tool_name")"; then
  printf 'ERROR: %s was not found inside its AI tool box. Run: ws-ai-setup\n' "$tool_name" >&2
  exit 127
fi

bridge_root="${HOME}/.local/share/ws-ai-project-shells/${project_box_name}"
bridge_shell="${bridge_root}/project-shell"
mkdir -p "$bridge_root"

cat >"$bridge_shell" <<'PROJECT_SHELL_BRIDGE'
#!/usr/bin/env bash
set -euo pipefail

if ! command -v distrobox-host-exec >/dev/null 2>&1; then
  printf 'ERROR: distrobox-host-exec is not available inside the AI tool box; cannot enter the project box.\n' >&2
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

run_interactive() {
  exec distrobox-host-exec distrobox-enter --name "$WS_PROJECT_BOX_NAME" -- \
    bash -lc '
      unset BASH_ENV ENV
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
      export SHELL=/bin/bash
      exec /bin/bash -l
    ' _ "$project_dir"
}

run_command_string() {
  local command_string="$1"
  shift

  if [[ "${WS_AI_BRIDGE_DEBUG:-0}" == "1" ]]; then
    printf 'project-shell: %s:%s :: %s\n' "$WS_PROJECT_BOX_NAME" "$project_dir" "$command_string" >&2
  fi

  exec distrobox-host-exec distrobox-enter --name "$WS_PROJECT_BOX_NAME" --no-tty -- \
    bash -lc '
      unset BASH_ENV ENV
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
      command_string="$1"
      shift
      export SHELL=/bin/bash
      exec /bin/bash -lc "$command_string" ws-ai-project-command "$@"
    ' _ "$project_dir" "$command_string" "$@"
}

run_direct() {
  if [[ "${WS_AI_BRIDGE_DEBUG:-0}" == "1" ]]; then
    printf 'project-shell direct: %s:%s ::' "$WS_PROJECT_BOX_NAME" "$project_dir" >&2
    printf ' %q' "$@" >&2
    printf '\n' >&2
  fi

  exec distrobox-host-exec distrobox-enter --name "$WS_PROJECT_BOX_NAME" --no-tty -- \
    bash -lc '
      unset BASH_ENV ENV
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
      export SHELL=/bin/bash
      exec "$@"
    ' _ "$project_dir" "$@"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -c)
      shift
      [[ "$#" -ge 1 ]] || {
        printf 'ERROR: -c requires a command string.\n' >&2
        exit 2
      }
      command_string="$1"
      shift
      run_command_string "$command_string" "$@"
      ;;
    -*c*)
      shift
      [[ "$#" -ge 1 ]] || {
        printf 'ERROR: shell option containing -c requires a command string.\n' >&2
        exit 2
      }
      command_string="$1"
      shift
      run_command_string "$command_string" "$@"
      ;;
    -l|-i|-li|-il)
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      run_direct "$@"
      ;;
    *)
      break
      ;;
  esac
done

if [[ "$#" -eq 0 ]]; then
  run_interactive
fi

run_direct "$@"
PROJECT_SHELL_BRIDGE

chmod +x "$bridge_shell"

export WS_PROJECT_BOX_NAME="$project_box_name"
export WS_AI_PROJECT_ROOT="$ai_project_root"
export WS_PROJECT_BOX_ROOT="$project_box_root"
export SHELL="$bridge_shell"
unset BASH_ENV ENV

cd "$start_dir" || exit 1

node_path="$(command -v node || true)"
first_line="$(head -n 1 "$tool_path" 2>/dev/null || true)"

case "$first_line" in
  *node*)
    if [ -z "$node_path" ]; then
      printf 'ERROR: %s needs Node inside its AI tool box, but node was not found. Run: ws-ai-setup\n' "$tool_name" >&2
      exit 127
    fi
    exec "$node_path" "$tool_path" "$@"
    ;;
  *)
    exec "$tool_path" "$@"
    ;;
esac
AI_RUNNER
LAUNCHER_BODY
} >"$launcher"

chmod +x "$launcher"

printf '__WS_AI_LAUNCHER_BIN__ %s\n' "$launcher_bin"
PROJECT_LAUNCHER_SETUP
  )"

  launcher_bin="$(
    printf '%s\n' "$launcher_output" |
      awk '/^__WS_AI_LAUNCHER_BIN__ / { sub(/^__WS_AI_LAUNCHER_BIN__ /, ""); value=$0 } END { if (value != "") print value }'
  )"

  [[ -n "$launcher_bin" ]] || die "Could not prepare ${tool} launcher inside ${project_box_name}."
}

prepare_project_launcher

exec distrobox-enter --name "$project_box_name" -- env \
  WS_AI_LAUNCHER_BIN="$launcher_bin" \
  bash -lc '
    set -euo pipefail
    project_dir="$1"
    launcher_bin="$2"
    tool_name="$3"
    shift 3

    cd "$project_dir" || exit 1
    export PATH="${launcher_bin}:${PATH}"
    exec "$tool_name" "$@"
  ' _ "$project_box_path" "$launcher_bin" "$tool" "$@"
