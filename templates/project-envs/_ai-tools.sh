#!/usr/bin/env bash
# Optional AI coding tools for project Distroboxes.
#
# Claude Code and Codex CLI are installed inside the selected project box only.
# Auth/config state is shared through /work/ai-state, which is mounted from
# ~/Boxes/ai-state on the host.

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

ensure_ai_state_mount() {
  if [[ ! -d /work/ai-state ]]; then
    cat >&2 <<'EOF'
ERROR: /work/ai-state is not available inside this project box.
       Recreate the project box with the current ws-new script, or manually
       mount ~/Boxes/ai-state into the box at /work/ai-state.
EOF
    exit 1
  fi

  mkdir -p /work/ai-state/claude /work/ai-state/codex
}

link_state_dir() {
  local link_path="$1"
  local target_path="$2"

  if [[ -L "$link_path" && "$(readlink "$link_path")" == "$target_path" ]]; then
    return 0
  fi

  if [[ ! -e "$link_path" && ! -L "$link_path" ]]; then
    ln -s "$target_path" "$link_path"
    return 0
  fi

  cat >&2 <<EOF
WARN: ${link_path} already exists and was not replaced.
      Shared AI state for this tool will not be linked automatically.
      Move it aside manually if you want to use ${target_path}.
EOF
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

ensure_ai_state_mount
install_node_for_ai_tools

if [[ "$WS_INSTALL_CLAUDE" == "1" ]]; then
  link_state_dir "${HOME}/.claude" /work/ai-state/claude
  npm install -g @anthropic-ai/claude-code
  command -v claude >/dev/null 2>&1 && claude --version || true
fi

if [[ "$WS_INSTALL_CODEX" == "1" ]]; then
  link_state_dir "${HOME}/.codex" /work/ai-state/codex
  npm install -g @openai/codex
  command -v codex >/dev/null 2>&1 && codex --version || true
fi

echo "AI tooling setup complete for ${project_name}."
