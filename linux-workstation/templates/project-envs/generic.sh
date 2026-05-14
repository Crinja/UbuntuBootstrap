#!/usr/bin/env bash
# Minimal generic Linux project environment template.

set -euo pipefail

project_mount="${1:-${HOME}/project}"

echo "Configuring generic project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates \
  curl \
  git \
  wget

echo "Generic project box is ready. No language SDKs were installed."
