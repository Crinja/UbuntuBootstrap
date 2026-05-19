#!/usr/bin/env bash
# Configure the Claude Code tool box.

set -euo pipefail

nvm_version="${NVM_VERSION:-v0.40.3}"

echo "Configuring claude-code."
echo "Claude Code will be installed inside claude-code, not on the host."

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
  tar \
  tree \
  unzip \
  wget \
  xdg-utils

export NVM_DIR="${HOME}/.nvm"
mkdir -p "$NVM_DIR"

if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
fi

# shellcheck source=/dev/null
source "${NVM_DIR}/nvm.sh"

nvm install --lts
nvm alias default 'lts/*'
nvm use default

nvm_block_start="# >>> claude-code nvm >>>"

if ! grep -Fxq "$nvm_block_start" "${HOME}/.bashrc" 2>/dev/null; then
  cat >>"${HOME}/.bashrc" <<'EOF'

# >>> claude-code nvm >>>
export NVM_DIR="${HOME}/.nvm"
if [ -s "${NVM_DIR}/nvm.sh" ]; then
  . "${NVM_DIR}/nvm.sh"
  nvm use default --silent >/dev/null 2>&1 || true
fi
# <<< claude-code nvm <<<
EOF
fi

npm install -g @anthropic-ai/claude-code

node --version
npm --version

if command -v claude >/dev/null 2>&1; then
  claude --version || true
fi

if command -v distrobox-host-exec >/dev/null 2>&1; then
  distrobox-host-exec --yes true || true
else
  cat >&2 <<'EOF'
WARN: distrobox-host-exec was not found inside claude-code.
      Project command bridging will not work until Distrobox host integration is
      available inside this box.
EOF
fi

cat <<'EOF'

claude-code is ready.

Inside claude-code:
  /work/projects contains host ~/Projects
  /work/scratch contains host ~/Scratch

Keep API keys, auth tokens, and local agent settings out of Git.
EOF
