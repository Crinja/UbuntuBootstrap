#!/usr/bin/env bash
# Python project environment template. Runs inside the project Distrobox.

set -euo pipefail

project_mount="${1:-${HOME}/project}"

echo "Configuring Python project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git \
  curl \
  ca-certificates \
  build-essential \
  python3 \
  python3-venv \
  python3-pip \
  pipx

python3 --version

cat <<EOF

Python is available inside this project box.

Recommended per-project virtual environment:
  cd ${project_mount}
  python3 -m venv .venv
  source .venv/bin/activate
  python -m pip install --upgrade pip

Avoid global pip installs. Keep project packages in .venv or another
project-local environment manager.
EOF
