#!/usr/bin/env bash
# Optional AI coding tools for project Distroboxes.
#
# Claude Code and Codex CLI are installed inside the selected project box only.
# Auth/config state stays in that project's custom Distrobox home.

set -euo pipefail

project_mount="${1:-${HOME}/project}"
project_name="${2:-$(basename "$project_mount")}"
: "${WS_INSTALL_CLAUDE:=0}"
: "${WS_INSTALL_CODEX:=0}"
: "${NVM_VERSION:=v0.40.3}"

if [[ "$WS_INSTALL_CLAUDE" != "1" && "$WS_INSTALL_CODEX" != "1" ]]; then
  echo "No AI tools selected; skipping AI tooling setup."
  exit 0
fi

localize_legacy_shared_dir() {
  local link_path="$1"
  local target_path=""

  if [[ -L "$link_path" ]]; then
    target_path="$(readlink "$link_path")"

    case "$target_path" in
      /work/ai-state/*)
        rm -f "$link_path"
        mkdir -p "$link_path"
        if [[ -d "$target_path" ]]; then
          cp -a "${target_path}/." "$link_path/"
        fi
        echo "Localized legacy shared AI directory: ${link_path}"
        ;;
      *)
        echo "Leaving existing symlink unchanged: ${link_path} -> ${target_path}"
        ;;
    esac
  elif [[ ! -e "$link_path" ]]; then
    mkdir -p "$link_path"
  fi
}

localize_legacy_shared_file() {
  local link_path="$1"
  local target_path=""

  if [[ -L "$link_path" ]]; then
    target_path="$(readlink "$link_path")"

    case "$target_path" in
      /work/ai-state/*)
        rm -f "$link_path"
        if [[ -f "$target_path" ]]; then
          cp "$target_path" "$link_path"
        fi
        echo "Localized legacy shared AI file: ${link_path}"
        ;;
      *)
        echo "Leaving existing symlink unchanged: ${link_path} -> ${target_path}"
        ;;
    esac
  fi
}

ensure_claude_json() {
  local target_path="${HOME}/.claude.json"
  local latest_backup=""
  local candidate

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    return 0
  fi

  shopt -s nullglob
  for candidate in "${HOME}/.claude"/backups/.claude.json.backup.*; do
    if [[ -z "$latest_backup" || "$candidate" -nt "$latest_backup" ]]; then
      latest_backup="$candidate"
    fi
  done
  shopt -u nullglob

  if [[ -n "$latest_backup" ]]; then
    cp "$latest_backup" "$target_path"
    echo "Restored Claude config from backup: ${latest_backup}"
  else
    printf '{}\n' >"$target_path"
  fi
}

install_node_for_ai_tools() {
  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl \
    git \
    xz-utils

  export NVM_DIR="${HOME}/.nvm"
  mkdir -p "$NVM_DIR"

  if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
  fi

  # shellcheck source=/dev/null
  source "${NVM_DIR}/nvm.sh"

  nvm install --lts
  nvm alias default 'lts/*'
  nvm use default

  if ! grep -Fxq "# >>> ws-ai nvm >>>" "${HOME}/.bashrc" 2>/dev/null; then
    cat >>"${HOME}/.bashrc" <<'EOF'

# >>> ws-ai nvm >>>
export NVM_DIR="${HOME}/.nvm"
if [ -s "${NVM_DIR}/nvm.sh" ]; then
  . "${NVM_DIR}/nvm.sh"
  nvm use default --silent >/dev/null 2>&1 || true
fi
# <<< ws-ai nvm <<<
EOF
  fi
}

echo "Configuring optional AI tools for ${project_name}."
echo "Project mount: ${project_mount}"

install_node_for_ai_tools

if [[ "$WS_INSTALL_CLAUDE" == "1" ]]; then
  localize_legacy_shared_dir "${HOME}/.claude"
  localize_legacy_shared_file "${HOME}/.claude.json"
  ensure_claude_json
  npm install -g @anthropic-ai/claude-code
  command -v claude >/dev/null 2>&1 && claude --version || true
fi

if [[ "$WS_INSTALL_CODEX" == "1" ]]; then
  localize_legacy_shared_dir "${HOME}/.codex"
  npm install -g @openai/codex
  command -v codex >/dev/null 2>&1 && codex --version || true
fi

echo "AI tooling setup complete for ${project_name}."
