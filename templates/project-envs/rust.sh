#!/usr/bin/env bash
# Rust project environment template. Runs inside the project Distrobox.

set -euo pipefail

project_mount="${1:-${HOME}/project}"

echo "Configuring Rust project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential \
  git \
  curl \
  pkg-config \
  libssl-dev \
  clang \
  lldb \
  cmake

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --default-toolchain stable
fi

# shellcheck source=/dev/null
source "${HOME}/.cargo/env"

rustup default stable

rustc --version
cargo --version

echo "Rust tooling is installed inside this Distrobox only."
