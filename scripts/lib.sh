#!/usr/bin/env bash
# Shared helpers for the workstation bootstrap scripts.

set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${LIB_DIR}/.." && pwd)"

: "${WS_DRY_RUN:=0}"
: "${WS_ASSUME_YES:=0}"

section() {
  printf '\n==> %s\n' "$*"
}

log() {
  printf '  - %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage_common_flags() {
  cat <<'EOF'
Common flags:
  --dry-run, -n   Print intended changes without applying them.
  --yes, -y       Assume yes for prompts where supported.
EOF
}

run() {
  if [[ "${WS_DRY_RUN}" == "1" ]]; then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

sudo_run() {
  if [[ "${EUID}" -eq 0 ]]; then
    run "$@"
  else
    run sudo "$@"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_not_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    die "Refusing to run as root. Run as your normal user; scripts will use sudo only where needed."
  fi
}

require_debian_like() {
  if [[ ! -r /etc/os-release ]]; then
    warn "Cannot read /etc/os-release; continuing because this may be a minimal Debian-like system."
    return 0
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  local id_like="${ID_LIKE:-}"
  local id="${ID:-}"

  case " ${id} ${id_like} " in
    *" ubuntu "*|*" debian "*)
      return 0
      ;;
    *)
      die "This bootstrap targets Ubuntu/Debian-like systems. Detected ID='${id}' ID_LIKE='${id_like}'."
      ;;
  esac
}

expand_user_path() {
  local path="$1"
  printf '%s\n' "${path/#\~/${HOME}}"
}

ensure_dir() {
  local path="$1"
  run mkdir -p "$path"
}

read_config_lines() {
  local file="$1"

  [[ -f "$file" ]] || die "Missing config file: $file"

  sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}

normalize_project_name() {
  local raw="$1"
  local normalized

  normalized="$(
    printf '%s' "$raw" |
      tr '[:upper:]' '[:lower:]' |
      sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
  )"

  [[ -n "$normalized" ]] || die "Project name '$raw' does not contain any usable name characters."
  printf '%s\n' "$normalized"
}

project_box_name() {
  local project_name="$1"
  printf 'project-%s\n' "$(normalize_project_name "$project_name")"
}

distrobox_names() {
  if ! command_exists distrobox-list; then
    return 0
  fi

  distrobox-list --no-color 2>/dev/null |
    awk -F'|' 'NR > 1 { gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 != "") print $2 }'
}

distrobox_exists() {
  local name="$1"
  distrobox_names | grep -Fxq "$name"
}

confirm() {
  local prompt="$1"
  local reply

  if [[ "${WS_ASSUME_YES}" == "1" ]]; then
    log "Assuming yes: $prompt"
    return 0
  fi

  read -r -p "${prompt} [y/N] " reply
  case "$reply" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

safe_remove_dir_under() {
  local target="$1"
  local allowed_root="$2"
  local resolved_target
  local resolved_root

  [[ -e "$target" || -L "$target" ]] || return 0
  resolved_target="$(readlink -f -- "$target")"
  resolved_root="$(readlink -f -- "$allowed_root")"

  case "$resolved_target" in
    "$resolved_root"/*)
      run rm -rf -- "$resolved_target"
      ;;
    *)
      die "Refusing to remove '$target'; it is outside '$allowed_root'."
      ;;
  esac
}

find_project_dir_by_normalized_name() {
  local requested="$1"
  local normalized_requested
  local candidate

  normalized_requested="$(normalize_project_name "$requested")"

  if [[ -d "${HOME}/Projects" ]]; then
    while IFS= read -r -d '' candidate; do
      if [[ "$(normalize_project_name "$(basename "$candidate")")" == "$normalized_requested" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done < <(find "${HOME}/Projects" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  fi

  printf '%s\n' "${HOME}/Projects/${requested}"
}

find_project_home_by_normalized_name() {
  local requested="$1"
  local normalized_requested
  local candidate

  normalized_requested="$(normalize_project_name "$requested")"

  if [[ -d "${HOME}/Boxes/projects" ]]; then
    while IFS= read -r -d '' candidate; do
      if [[ "$(normalize_project_name "$(basename "$candidate")")" == "$normalized_requested" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done < <(find "${HOME}/Boxes/projects" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  fi

  printf '%s\n' "${HOME}/Boxes/projects/${requested}"
}
