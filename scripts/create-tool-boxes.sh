#!/usr/bin/env bash
# Create the small set of always-present AI tool boxes.
#
# Custom --home paths reduce dotfile/config contamination on the host, but
# Distrobox is a workflow and contamination-control tool, not a hard security
# boundary.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/create-tool-boxes.sh [--dry-run]

Creates tool boxes from config/tool-boxes.conf:
  name|image|home|optional-semicolon-separated-volumes
EOF
}

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
      die "Unknown option: $1"
      ;;
  esac
done

section "Tool Distrobox creation"
if ! command_exists distrobox-create; then
  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    warn "distrobox-create is not installed, but continuing because dry-run mode is enabled."
  else
    die "distrobox-create is not installed. Run install-host-packages.sh first."
  fi
fi

config_file="${REPO_ROOT}/config/tool-boxes.conf"

expand_volume_spec() {
  local spec="$1"
  local source_path
  local rest

  if [[ "$spec" == *:* ]]; then
    source_path="${spec%%:*}"
    rest="${spec#*:}"
    printf '%s:%s\n' "$(expand_user_path "$source_path")" "$rest"
  else
    expand_user_path "$spec"
  fi
}

ensure_volume_source_dir() {
  local spec="$1"
  local source_path

  source_path="${spec%%:*}"

  if [[ "$source_path" = /* ]]; then
    ensure_dir "$source_path"
  fi
}

while IFS='|' read -r name image home_path volumes; do
  [[ -n "${name:-}" ]] || continue
  [[ -n "${image:-}" ]] || die "Missing image for tool box '$name'."
  [[ -n "${home_path:-}" ]] || die "Missing home path for tool box '$name'."

  home_path="$(expand_user_path "$home_path")"

  ensure_dir "$home_path"

  create_args=(
    distrobox-create
    --name "$name"
    --image "$image"
    --home "$home_path"
    --yes
  )

  if [[ -n "${volumes:-}" ]]; then
    IFS=';' read -r -a volume_specs <<<"$volumes"
    for volume_spec in "${volume_specs[@]}"; do
      [[ -n "$volume_spec" ]] || continue
      expanded_volume="$(expand_volume_spec "$volume_spec")"
      ensure_volume_source_dir "$expanded_volume"
      create_args+=(--volume "$expanded_volume")
    done
  fi

  if distrobox_exists "$name"; then
    log "Tool box already exists: $name"
    continue
  fi

  log "Creating tool box '$name' from '$image' with home '$home_path'."
  run "${create_args[@]}"
done < <(read_config_lines "$config_file")

log "Tool Distrobox creation complete."
