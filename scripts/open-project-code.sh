#!/usr/bin/env bash
# Launch the VS Code Flatpak with a project-specific profile.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/open-project-code.sh <project-name> [code-args...]

Options:
  --profile <name>   Use a custom VS Code profile name.
  --no-profile       Launch without selecting a VS Code profile.
  --app-id <id>      Flatpak app ID. Default: com.visualstudio.code

Examples:
  ws-code ExampleProject
  ws-code ExampleProject .
  ws-code --profile rust-nightly CompilerExperiment

VS Code is launched from Flatpak. Project-specific extensions and settings live
in the selected VS Code profile.
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  usage
  exit 0
fi

app_id="${WS_VSCODE_FLATPAK_APP_ID:-com.visualstudio.code}"
profile_name=""
use_profile=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || die "--profile requires a value."
      profile_name="$2"
      shift 2
      ;;
    --no-profile)
      use_profile=0
      shift
      ;;
    --app-id)
      [[ $# -ge 2 ]] || die "--app-id requires a value."
      app_id="$2"
      shift 2
      ;;
    --box)
      die "--box is no longer supported. VS Code is now launched as a Flatpak with: ws-code <project-name>"
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "Unknown ws-code option: $1"
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -ge 1 ]] || die "Missing project name."

project_name="$1"
normalized_project="$(normalize_project_name "$project_name")"
project_dir="$(find_project_dir_by_normalized_name "$project_name")"
shift

[[ -d "$project_dir" ]] || die "Project folder does not exist: $project_dir"

if [[ -z "$profile_name" ]]; then
  profile_name="project-${normalized_project}"
fi

command_exists flatpak || die "flatpak is not installed. Run ./bootstrap.sh first."

if ! flatpak info "$app_id" >/dev/null 2>&1; then
  die "VS Code Flatpak '${app_id}' is not installed. Run: ./scripts/install-flatpaks.sh"
fi

if [[ $# -eq 0 ]]; then
  set -- "$project_dir"
else
  code_args=()
  for arg in "$@"; do
    case "$arg" in
      .)
        code_args+=("$project_dir")
        ;;
      ./*)
        code_args+=("${project_dir}/${arg#./}")
        ;;
      *)
        code_args+=("$arg")
        ;;
    esac
  done
  set -- "${code_args[@]}"
fi

if [[ "$use_profile" -eq 1 ]]; then
  exec flatpak run "$app_id" --profile "$profile_name" "$@"
fi

exec flatpak run "$app_id" "$@"
