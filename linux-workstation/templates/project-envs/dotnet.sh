#!/usr/bin/env bash
# .NET project environment template. Runs inside the project Distrobox.

set -euo pipefail

project_mount="${1:-${HOME}/project}"

echo "Configuring .NET project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git \
  curl \
  wget \
  ca-certificates \
  apt-transport-https

cat <<'EOF'

TODO: Install the .NET SDK version required by this project.

Recommended practice:
  1. Add a global.json file to the project repository.
  2. Pin the SDK version in global.json.
  3. Install that matching SDK inside this Distrobox only.

Microsoft's Ubuntu package feed is the usual route for SDK installs, but this
template intentionally does not pick a version for you. Pinning the SDK is a
project decision, not a host decision.

Example global.json shape:
  {
    "sdk": {
      "version": "8.0.100",
      "rollForward": "latestFeature"
    }
  }

EOF

if command -v dotnet >/dev/null 2>&1; then
  dotnet --info
else
  echo "dotnet is not installed yet. Install the pinned SDK inside this project box."
fi
