#!/usr/bin/env bash
# Node.js project environment template. Runs inside the project Distrobox.

set -euo pipefail

project_mount="${1:-${HOME}/project}"
nvm_version="${NVM_VERSION:-v0.40.3}"

echo "Configuring Node.js project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git \
  curl \
  ca-certificates \
  build-essential

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

node --version
npm --version

echo "Node/npm are installed inside this Distrobox only."
