#!/usr/bin/env bash
# Rust nightly project environment template. Runs inside the project Distrobox.

set -euo pipefail

project_mount="${1:-${HOME}/project}"

echo "Configuring Rust nightly project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential \
  clang \
  cmake \
  curl \
  git \
  libssl-dev \
  lldb \
  pkg-config

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --default-toolchain nightly
fi

# shellcheck source=/dev/null
source "${HOME}/.cargo/env"

rustup toolchain install nightly
rustup default nightly

rustc --version
cargo --version

echo "Nightly Rust is installed inside this project Distrobox only."
