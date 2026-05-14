#!/usr/bin/env bash
# C/C++ project environment template. Runs inside the project Distrobox.

set -euo pipefail

project_mount="${1:-${HOME}/project}"

echo "Configuring C/C++ project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential \
  clang \
  clang-format \
  cmake \
  gdb \
  lldb \
  make \
  ninja-build \
  pkg-config \
  valgrind

cc --version | head -n 1
c++ --version | head -n 1
cmake --version | head -n 1

echo "C/C++ tooling is installed inside this Distrobox only."
