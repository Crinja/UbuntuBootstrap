#!/usr/bin/env bash
# Print a non-destructive status report for the workstation setup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify.sh

Checks host tools, folders, tool boxes, optional Flatpaks, wrappers, and Bash integration.
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

ok=0
fail=0

check_pass() {
  printf 'PASS: %s\n' "$1"
  ok=$((ok + 1))
}

check_fail() {
  printf 'FAIL: %s\n' "$1"
  fail=$((fail + 1))
}

check_command() {
  local command_name="$1"
  if command_exists "$command_name"; then
    check_pass "$command_name installed"
  else
    check_fail "$command_name installed"
  fi
}

check_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    check_pass "$path exists"
  else
    check_fail "$path exists"
  fi
}

section "Verification"

check_command flatpak

if command_exists flatpak && flatpak remotes --columns=name 2>/dev/null | grep -Fxq flathub; then
  check_pass "Flathub configured"
else
  check_fail "Flathub configured"
fi

check_command podman
check_command distrobox
check_command distrobox-create

for folder in \
  "${HOME}/Projects" \
  "${HOME}/Boxes" \
  "${HOME}/Boxes/projects" \
  "${HOME}/VMs" \
  "${HOME}/Scratch" \
  "${HOME}/Downloads/Quarantine"; do
  check_path "$folder"
done

if command_exists distrobox-list; then
  while IFS='|' read -r name _image _home_path; do
    if distrobox_exists "$name"; then
      check_pass "tool Distrobox exists: $name"
    else
      check_fail "tool Distrobox exists: $name"
    fi
  done < <(read_config_lines "${REPO_ROOT}/config/tool-boxes.conf")
else
  check_fail "tool Distrobox status available"
fi

mapfile -t configured_flatpaks < <(read_config_lines "${REPO_ROOT}/config/flatpaks.txt")

if [[ "${#configured_flatpaks[@]}" -eq 0 ]]; then
  check_pass "no Flatpak applications configured"
elif command_exists flatpak; then
  for app_id in "${configured_flatpaks[@]}"; do
    if flatpak info "$app_id" >/dev/null 2>&1; then
      check_pass "Flatpak installed: $app_id"
    else
      check_fail "Flatpak installed: $app_id"
    fi
  done
else
  check_fail "Flatpak app status available"
fi

for wrapper in ws-new ws-enter ws-code ws-ai-setup ws-claude ws-codex ws-list ws-remove ws-help; do
  if [[ -x "${REPO_ROOT}/bin/${wrapper}" ]]; then
    check_pass "wrapper executable: $wrapper"
  else
    check_fail "wrapper executable: $wrapper"
  fi
done

if [[ -f "${REPO_ROOT}/dotfiles/bashrc.append" ]]; then
  check_pass "Bash integration snippet exists: dotfiles/bashrc.append"
else
  check_fail "Bash integration snippet exists: dotfiles/bashrc.append"
fi

if [[ -f "${HOME}/.bashrc" ]] &&
  {
    grep -Fxq "# >>> UbuntuBootstrap ws commands >>>" "${HOME}/.bashrc" ||
      grep -Fxq "# >>> linux-workstation ws commands >>>" "${HOME}/.bashrc"
  }; then
  check_pass "~/.bashrc sources workstation commands"
else
  check_fail "~/.bashrc sources workstation commands"
fi

printf '\nSummary: %s passed, %s failed\n' "$ok" "$fail"

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
