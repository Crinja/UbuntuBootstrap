#!/usr/bin/env bash
# Configure the dev-base Distrobox. Run from the repo root with:
#   distrobox-enter --name dev-base -- bash -s < boxes/dev-base.sh
#
# This box contains IDE and workflow basics only. It is useful for editing,
# Git, notes, and unusual one-off environments, but project SDKs still belong
# in project-scoped boxes.

set -euo pipefail

echo "Configuring dev-base."
echo "This installs VS Code and workflow basics inside dev-base, not on the host."

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  desktop-file-utils \
  file \
  fd-find \
  git \
  git-lfs \
  gnupg \
  gpg \
  gvfs \
  htop \
  jq \
  less \
  libglib2.0-bin \
  lsb-release \
  neovim \
  openssh-client \
  ripgrep \
  shellcheck \
  tar \
  tree \
  unzip \
  wget \
  xdg-utils \
  xz-utils \
  zip

if ! command -v code >/dev/null 2>&1; then
  tmp_key="$(mktemp)"
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor >"$tmp_key"

  sudo install -D -o root -g root -m 644 "$tmp_key" /usr/share/keyrings/microsoft.gpg
  rm -f "$tmp_key"

  sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y code
fi

code --version | head -n 1

if command -v distrobox-export >/dev/null 2>&1; then
  distrobox-export --app code || {
    echo "VS Code installed, but distrobox-export could not export the desktop launcher."
    echo "You can still launch it with: ws-code --base"
  }
fi

echo "dev-base is ready. Keep SDKs in project boxes."
