#!/usr/bin/env bash
# PHP project environment template. Runs inside the project Distrobox.

set -euo pipefail

project_mount="${1:-${HOME}/project}"

echo "Configuring PHP project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git \
  curl \
  ca-certificates \
  php-cli \
  php-mbstring \
  php-xml \
  php-sqlite3 \
  composer

php --version

if command -v composer >/dev/null 2>&1; then
  composer --version
else
  echo "Composer was not installed by apt on this image. Install it inside this box if the project needs it."
fi

echo "PHP tooling is installed inside this Distrobox only."
