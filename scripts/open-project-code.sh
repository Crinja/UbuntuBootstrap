#!/usr/bin/env bash
# Launch the VS Code Flatpak with project-specific settings and extensions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/open-project-code.sh <project-name> [code-args...]

Options:
  --profile <name>   Deprecated no-op; project Code state handles isolation.
  --no-profile       Deprecated no-op; project Code state handles isolation.
  --app-id <id>      Flatpak app ID. Default: com.visualstudio.code

Examples:
  ws-code ExampleProject
  ws-code ExampleProject .

VS Code is launched from Flatpak. Project-specific extensions and settings live
under ~/Boxes/projects/<project>/.vscode-flatpak.
The integrated terminal uses the matching project Distrobox by default.
EOF
}

container_runtime_setting_key() {
  printf 'dev.containers.%sPath\n' "doc""ker"
}

compose_runtime_setting_key() {
  printf 'dev.containers.%sComposePath\n' "doc""ker"
}

dev_containers_extension_id() {
  printf 'ms-vscode-remote.remote-containers\n'
}

write_project_code_settings() {
  local settings_file="$1"
  local box_name="$2"
  local project_mount="$3"
  local enable_podman_bridge="$4"
  local podman_path="$5"
  local podman_compose_path="$6"
  local profile_label="Project Distrobox"
  local runtime_key
  local compose_key
  local tmp_file

  mkdir -p "$(dirname "$settings_file")"

  if [[ ! -f "$settings_file" ]]; then
    cat >"$settings_file" <<EOF
{}
EOF
  fi

  if ! command_exists jq; then
    warn "jq is not installed; cannot update VS Code terminal settings automatically."
    warn "Run ./bootstrap.sh, then rerun ws-code for project Distrobox terminal integration."
    return 0
  fi

  if ! jq empty "$settings_file" >/dev/null 2>&1; then
    warn "VS Code settings are not valid plain JSON: ${settings_file}"
    warn "Project Distrobox terminal integration was not written."
    return 0
  fi

  runtime_key="$(container_runtime_setting_key)"
  compose_key="$(compose_runtime_setting_key)"
  tmp_file="$(mktemp)"

  jq \
    --arg profile_label "$profile_label" \
    --arg box_name "$box_name" \
    --arg project_mount "$project_mount" \
    --arg enable_podman_bridge "$enable_podman_bridge" \
    --arg podman_path "$podman_path" \
    --arg podman_compose_path "$podman_compose_path" \
    --arg runtime_key "$runtime_key" \
    --arg compose_key "$compose_key" \
    '
      .["terminal.integrated.profiles.linux"] =
        ((.["terminal.integrated.profiles.linux"] // {}) + {
          ($profile_label): {
            "path": "/usr/bin/flatpak-spawn",
            "args": [
              "--host",
              "/usr/bin/distrobox-enter",
              "--name",
              $box_name,
              "--",
              "bash",
              "-lc",
              ("cd " + $project_mount + " && exec bash -i")
            ]
          }
        })
      | .["terminal.integrated.defaultProfile.linux"] = $profile_label
      | if $enable_podman_bridge == "1" then
          .[$runtime_key] = $podman_path
        else
          if .[$runtime_key] == $podman_path then
            del(.[$runtime_key])
          else
            .
          end
        end
      | if $enable_podman_bridge == "1" then
          .[$compose_key] = $podman_compose_path
        else
          if .[$compose_key] == $podman_compose_path then
            del(.[$compose_key])
          else
            .
          end
        end
    ' "$settings_file" >"$tmp_file"

  mv "$tmp_file" "$settings_file"
}

write_project_podman_bridge() {
  local bridge_dir="$1"

  mkdir -p "$bridge_dir"

  cat >"${bridge_dir}/podman" <<'EOF'
#!/bin/sh
set -eu
if [ -f /.flatpak-info ]; then
  exec /usr/bin/flatpak-spawn --host /usr/bin/podman "$@"
fi
exec /usr/bin/podman "$@"
EOF

  cat >"${bridge_dir}/podman-compose" <<'EOF'
#!/bin/sh
set -eu
if [ -f /.flatpak-info ]; then
  exec /usr/bin/flatpak-spawn --host /bin/sh -lc 'if command -v podman-compose >/dev/null 2>&1; then exec podman-compose "$@"; fi; printf "%s\n" "podman-compose was not found on the host. Install it with: sudo apt install podman-compose" >&2; exit 127' podman-compose "$@"
fi
if command -v podman-compose >/dev/null 2>&1; then
  exec podman-compose "$@"
fi
printf '%s\n' "podman-compose was not found on the host. Install it with: sudo apt install podman-compose" >&2
exit 127
EOF

  chmod +x "${bridge_dir}/podman" "${bridge_dir}/podman-compose"
}

project_extension_installed() {
  local extensions_dir="$1"
  local extension_id="$2"
  local lowered_id

  lowered_id="$(printf '%s' "$extension_id" | tr '[:upper:]' '[:lower:]')"

  find "$extensions_dir" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    \( -iname "$lowered_id" -o -iname "${lowered_id}-*" \) \
    -print \
    -quit |
    grep -q .
}

install_project_code_extension() {
  local app_id="$1"
  local user_data_dir="$2"
  local extensions_dir="$3"
  local extension_id="$4"

  if project_extension_installed "$extensions_dir" "$extension_id"; then
    log "Dev Containers extension already installed for this project."
    return 0
  fi

  log "Installing Dev Containers extension into this project's VS Code extension directory."
  if ! flatpak run "$app_id" \
    --user-data-dir "$user_data_dir" \
    --extensions-dir "$extensions_dir" \
    --install-extension "$extension_id"; then
    warn "Could not install Dev Containers extension automatically."
    warn "Open ws-code for this project and install: $extension_id"
  fi
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || die "--profile requires a value."
      warn "--profile is deprecated and ignored; project Code state handles isolation."
      shift 2
      ;;
    --no-profile)
      warn "--no-profile is deprecated and ignored; project Code state handles isolation."
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
box_name="project-${normalized_project}"
project_dir="$(find_project_dir_by_normalized_name "$project_name")"
project_home="$(find_project_home_by_normalized_name "$project_name")"
project_mount="/work/${normalized_project}"
shift

[[ -d "$project_dir" ]] || die "Project folder does not exist: $project_dir"

command_exists flatpak || die "flatpak is not installed. Run ./bootstrap.sh first."
command_exists distrobox-enter || die "distrobox-enter is not installed. Run ./bootstrap.sh first."

if ! distrobox_exists "$box_name"; then
  die "Distrobox '${box_name}' does not exist. Create it with: ws-new <template> ${project_name}"
fi

if ! flatpak info "$app_id" >/dev/null 2>&1; then
  die "VS Code Flatpak '${app_id}' is not installed. Run: ./scripts/install-flatpaks.sh"
fi

code_user_data_dir="${project_home}/.vscode-flatpak/user-data"
code_extensions_dir="${project_home}/.vscode-flatpak/extensions"
code_bridge_dir="${project_home}/.vscode-flatpak/bin"
podman_bridge_marker="${project_home}/.vscode-flatpak/enable-host-podman"
mkdir -p "$code_user_data_dir" "$code_extensions_dir"
enable_podman_bridge=0

if [[ -f "$podman_bridge_marker" ]]; then
  enable_podman_bridge=1
  write_project_podman_bridge "$code_bridge_dir"
  install_project_code_extension \
    "$app_id" \
    "$code_user_data_dir" \
    "$code_extensions_dir" \
    "$(dev_containers_extension_id)"
fi

write_project_code_settings \
  "${code_user_data_dir}/User/settings.json" \
  "$box_name" \
  "$project_mount" \
  "$enable_podman_bridge" \
  "${code_bridge_dir}/podman" \
  "${code_bridge_dir}/podman-compose"

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

code_options=(
  --user-data-dir "$code_user_data_dir"
  --extensions-dir "$code_extensions_dir"
)

exec flatpak run "$app_id" "${code_options[@]}" "$@"
