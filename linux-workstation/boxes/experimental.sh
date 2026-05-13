#!/usr/bin/env bash
# Configure the experimental base box. Run inside the experimental Distrobox:
#   distrobox-enter --name experimental -- bash -s < boxes/experimental.sh
#
# This is for non-hostile experiments. Use a VM for genuinely untrusted software.

set -euo pipefail

echo "Configuring experimental base box."

sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git \
  curl \
  wget \
  ca-certificates \
  build-essential

cat <<'EOF'

experimental is ready.

Reminder:
  Distrobox shares meaningful parts of your user session with the host. It is
  useful for workflow separation and host cleanliness, not malware analysis.
  Use a VM for genuinely untrusted software.
EOF
