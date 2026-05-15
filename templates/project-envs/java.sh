#!/usr/bin/env bash
# Java project environment template. Runs inside the project Distrobox.

set -euo pipefail

project_mount="${1:-${HOME}/project}"

echo "Configuring Java project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  gradle \
  maven \
  openjdk-21-jdk

java -version
javac -version

if command -v mvn >/dev/null 2>&1; then
  mvn --version | head -n 1
fi

if command -v gradle >/dev/null 2>&1; then
  gradle --version | sed -n '1,3p'
fi

echo "Java tooling is installed inside this Distrobox only."
