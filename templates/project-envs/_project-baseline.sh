#!/usr/bin/env bash
# Shared project baseline for project Distroboxes.
#
# This installs editor and workflow basics only. It intentionally does not
# install language SDKs, databases, or project-specific CLIs.

set -euo pipefail

project_mount="${1:-${HOME}/project}"
project_name="${2:-$(basename "$project_mount")}"
: "${WS_INSTALL_VSCODE:=1}"

install_project_baseline_packages() {
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
}

install_vscode() {
  if command -v code >/dev/null 2>&1; then
    code --version | head -n 1
    return 0
  fi

  local tmp_key
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
  code --version | head -n 1
}

echo "Configuring project baseline for ${project_name}."
echo "Project mount: ${project_mount}"

install_project_baseline_packages

if [[ "$WS_INSTALL_VSCODE" == "1" ]]; then
  install_vscode
else
  echo "Skipping VS Code install because WS_INSTALL_VSCODE=${WS_INSTALL_VSCODE}."
fi

echo "Project baseline tooling is ready. No language SDKs were installed by this layer."
