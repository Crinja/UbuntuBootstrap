#!/usr/bin/env bash
# Configure the uni-work base box. Run inside the uni-work Distrobox:
#   distrobox-enter --name uni-work -- bash -s < boxes/uni-work.sh
#
# This is for general university work, not for project-specific dev stacks.

set -euo pipefail

echo "Configuring uni-work base box."

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git \
  curl \
  ca-certificates \
  build-essential \
  python3 \
  python3-venv \
  openjdk-21-jdk \
  sqlite3

echo "uni is ready. Keep course-specific tooling in project boxes when possible."
