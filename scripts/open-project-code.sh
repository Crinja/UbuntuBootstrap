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

write_project_code_settings() {
  local settings_file="$1"
  local box_name="$2"
  local project_mount="$3"
  local enable_docker_bridge="$4"
  local docker_path="$5"
  local docker_compose_path="$6"
  local profile_label="Project Distrobox"
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

  tmp_file="$(mktemp)"
  jq \
    --arg profile_label "$profile_label" \
    --arg box_name "$box_name" \
    --arg project_mount "$project_mount" \
    --arg enable_docker_bridge "$enable_docker_bridge" \
    --arg docker_path "$docker_path" \
    --arg docker_compose_path "$docker_compose_path" \
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
      | if $enable_docker_bridge == "1" then
          .["dev.containers.dockerPath"] = $docker_path
        else
          if .["dev.containers.dockerPath"] == $docker_path then
            del(.["dev.containers.dockerPath"])
          else
            .
          end
        end
      | if $enable_docker_bridge == "1" then
          .["dev.containers.dockerComposePath"] = $docker_compose_path
        else
          if .["dev.containers.dockerComposePath"] == $docker_compose_path then
            del(.["dev.containers.dockerComposePath"])
          else
            .
          end
        end
    ' "$settings_file" >"$tmp_file"

  mv "$tmp_file" "$settings_file"
}

shell_quote() {
  local value="$1"

  printf "'"
  printf '%s' "$value" | sed "s/'/'\\\\''/g"
  printf "'"
}

write_project_docker_bridge() {
  local bridge_dir="$1"
  local box_name="$2"
  local project_name="$3"
  local project_dir="$4"
  local project_mount="$5"
  local quoted_box_name
  local quoted_project_name
  local quoted_project_dir
  local quoted_project_mount
  local quoted_runner

  mkdir -p "$bridge_dir"

  quoted_box_name="$(shell_quote "$box_name")"
  quoted_project_name="$(shell_quote "$project_name")"
  quoted_project_dir="$(shell_quote "$project_dir")"
  quoted_project_mount="$(shell_quote "$project_mount")"
  quoted_runner="$(shell_quote "${bridge_dir}/docker-bridge-runner")"

  cat >"${bridge_dir}/docker-bridge-runner" <<EOF
#!/usr/bin/env bash
set -euo pipefail

box_name=${quoted_box_name}
project_name=${quoted_project_name}
host_project_dir=${quoted_project_dir}
project_mount=${quoted_project_mount}
docker_command="\${1:?missing docker command}"
shift

args=()
for arg in "\$@"; do
  args+=("\${arg//\${host_project_dir}/\${project_mount}}")
done

needs_daemon=1
case "\${args[0]:-}" in
  --version|-v|help|-h|--help)
    needs_daemon=0
    ;;
esac

project_docker_info() {
  /usr/bin/distrobox-enter --name "\$box_name" -- docker info >/dev/null 2>&1
}

try_start_project_docker() {
  /usr/bin/distrobox-enter --name "\$box_name" -- bash -lc '
    if docker info >/dev/null 2>&1; then
      exit 0
    fi

    if command -v service >/dev/null 2>&1; then
      sudo -n service docker start >/dev/null 2>&1 || true
    fi

    for _ in 1 2 3; do
      if docker info >/dev/null 2>&1; then
        exit 0
      fi
      sleep 1
    done

    exit 1
  '
}

if [[ "\$needs_daemon" -eq 1 ]] && ! project_docker_info; then
  try_start_project_docker || {
    cat >&2 <<BRIDGE_ERROR
Docker is installed in \$box_name, but its daemon/socket is not running.

From the host, run:
  ws-docker-start \$project_name

Then reopen VS Code:
  ws-code \$project_name
BRIDGE_ERROR
    exit 1
  }
fi

case "\$docker_command" in
  docker)
    exec /usr/bin/distrobox-enter --name "\$box_name" -- bash -lc 'cd "\$1"; shift; exec docker "\$@"' docker "\$project_mount" "\${args[@]}"
    ;;
  docker-compose)
    exec /usr/bin/distrobox-enter --name "\$box_name" -- bash -lc 'cd "\$1"; shift; if command -v docker-compose >/dev/null 2>&1; then exec docker-compose "\$@"; fi; exec docker compose "\$@"' docker-compose "\$project_mount" "\${args[@]}"
    ;;
  *)
    printf 'Unsupported Docker bridge command: %s\n' "\$docker_command" >&2
    exit 64
    ;;
esac
EOF

  cat >"${bridge_dir}/docker" <<EOF
#!/bin/sh
set -eu
runner=${quoted_runner}
if [ -f /.flatpak-info ]; then
  exec /usr/bin/flatpak-spawn --host /usr/bin/env bash "\$runner" docker "\$@"
fi
exec /usr/bin/env bash "\$runner" docker "\$@"
EOF

  cat >"${bridge_dir}/docker-compose" <<EOF
#!/bin/sh
set -eu
runner=${quoted_runner}
if [ -f /.flatpak-info ]; then
  exec /usr/bin/flatpak-spawn --host /usr/bin/env bash "\$runner" docker-compose "\$@"
fi
exec /usr/bin/env bash "\$runner" docker-compose "\$@"
EOF

  chmod +x "${bridge_dir}/docker-bridge-runner" "${bridge_dir}/docker" "${bridge_dir}/docker-compose"
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
docker_bridge_marker="${project_home}/.vscode-flatpak/enable-project-docker"
mkdir -p "$code_user_data_dir" "$code_extensions_dir"
enable_docker_bridge=0

if [[ -f "$docker_bridge_marker" ]]; then
  enable_docker_bridge=1
  write_project_docker_bridge "$code_bridge_dir" "$box_name" "$project_name" "$project_dir" "$project_mount"
fi

write_project_code_settings \
  "${code_user_data_dir}/User/settings.json" \
  "$box_name" \
  "$project_mount" \
  "$enable_docker_bridge" \
  "${code_bridge_dir}/docker" \
  "${code_bridge_dir}/docker-compose"

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
