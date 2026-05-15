#!/usr/bin/env bash
# C#/.NET project environment template. Runs inside the project Distrobox.

set -euo pipefail

project_mount="${1:-${HOME}/project}"

echo "Configuring C#/.NET project environment."
echo "Project mount: ${project_mount}"

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  git \
  wget

cat <<'EOF'

.NET SDK policy:
  This template does not choose a default SDK for you. Pin the SDK version in
  the repository with global.json, then install the matching SDK inside this
  project box.

Optional one-shot install:
  DOTNET_SDK_PACKAGE=dotnet-sdk-8.0 ws-new csharp MyApi

If DOTNET_SDK_PACKAGE is set, this template will attempt to install that apt
package inside the project box.

EOF

if [[ -n "${DOTNET_SDK_PACKAGE:-}" ]]; then
  echo "Installing requested .NET SDK package: ${DOTNET_SDK_PACKAGE}"
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$DOTNET_SDK_PACKAGE"
fi

if command -v dotnet >/dev/null 2>&1; then
  dotnet --info
else
  echo "dotnet is not installed yet. Install the pinned SDK inside this project box."
fi
