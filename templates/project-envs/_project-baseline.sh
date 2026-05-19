#!/usr/bin/env bash
# Shared project baseline for project Distroboxes.
#
# This installs workflow basics only. It intentionally does not install language
# SDKs, databases, GUI editors, or project-specific CLIs.

set -euo pipefail

project_mount="${1:-${HOME}/project}"
project_name="${2:-$(basename "$project_mount")}"

install_project_baseline_packages() {
  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl \
    file \
    fd-find \
    git \
    git-lfs \
    gnupg \
    htop \
    jq \
    less \
    lsb-release \
    neovim \
    openssh-client \
    ripgrep \
    shellcheck \
    tar \
    tree \
    unzip \
    wget \
    xz-utils \
    zip
}

echo "Configuring project baseline for ${project_name}."
echo "Project mount: ${project_mount}"

install_project_baseline_packages

echo "Project baseline tooling is ready. No GUI editor or language SDKs were installed by this layer."
