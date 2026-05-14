#!/usr/bin/env bash
# Configure the single AI coding tools Distrobox. Run from the repo root with:
#   distrobox-enter --name ai-code -- bash -s < boxes/ai-code.sh
#
# This box is outside the host and shared across projects. It mounts:
#   ~/Projects -> /work/projects
#   ~/Scratch  -> /work/scratch

set -euo pipefail

nvm_version="${NVM_VERSION:-v0.40.3}"

echo "Configuring ai-code."
echo "Claude Code and Codex CLI will be installed inside ai-code, not on the host."

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates \
  curl \
  fd-find \
  git \
  git-lfs \
  gnupg \
  jq \
  less \
  openssh-client \
  ripgrep \
  shellcheck \
  tree \
  unzip \
  wget \
  xdg-utils

export NVM_DIR="${HOME}/.nvm"

if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
fi

# shellcheck source=/dev/null
source "${NVM_DIR}/nvm.sh"

nvm install --lts
nvm alias default 'lts/*'
nvm use default

nvm_block_start="# >>> ai-code nvm >>>"
nvm_block_end="# <<< ai-code nvm <<<"

if ! grep -Fxq "$nvm_block_start" "${HOME}/.bashrc" 2>/dev/null; then
  cat >>"${HOME}/.bashrc" <<'EOF'

# >>> ai-code nvm >>>
export NVM_DIR="${HOME}/.nvm"
if [ -s "${NVM_DIR}/nvm.sh" ]; then
  . "${NVM_DIR}/nvm.sh"
  nvm use default --silent >/dev/null 2>&1 || true
fi
# <<< ai-code nvm <<<
EOF
fi

npm install -g @anthropic-ai/claude-code
npm install -g @openai/codex

node --version
npm --version

if command -v claude >/dev/null 2>&1; then
  claude --version || true
fi

if command -v codex >/dev/null 2>&1; then
  codex --version || true
fi

cat <<'EOF'

ai-code is ready.

Common host-side commands:
  ws-claude TerraKit
  ws-codex TerraKit
  ws-ai-shell TerraKit

Inside ai-code:
  /work/projects contains host ~/Projects
  /work/scratch contains host ~/Scratch

Keep API keys, auth tokens, and local agent settings out of Git.
EOF
