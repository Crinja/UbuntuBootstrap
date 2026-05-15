#!/usr/bin/env bash
# Optional Docker tooling for project Distroboxes.
#
# This is for trusted development/devcontainer work inside one project box. It
# does not install Docker on the host and it is not enabled for every project.

set -euo pipefail

project_mount="${1:-${HOME}/project}"
project_name="${2:-$(basename "$project_mount")}"

package_available() {
  apt-cache show "$1" >/dev/null 2>&1
}

install_docker_packages() {
  local -a packages
  local compose_package_found

  packages=(docker.io)
  compose_package_found=0

  sudo apt-get update

  if package_available docker-buildx; then
    packages+=(docker-buildx)
  fi

  if package_available docker-compose-v2; then
    packages+=(docker-compose-v2)
    compose_package_found=1
  elif package_available docker-compose; then
    packages+=(docker-compose)
    compose_package_found=1
  fi

  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"

  if [[ "$compose_package_found" -ne 1 ]]; then
    echo "WARN: No Docker Compose package was found in the Ubuntu apt sources."
  fi
}

configure_docker_group() {
  local user_name

  user_name="$(id -un)"
  sudo groupadd -f docker

  if ! sudo usermod -aG docker "$user_name"; then
    echo "WARN: Could not add ${user_name} to the docker group."
    echo "      Docker may require sudo inside this project box."
  fi
}

try_start_docker_service() {
  if docker info >/dev/null 2>&1; then
    echo "Docker daemon is already reachable."
    return 0
  fi

  if command -v service >/dev/null 2>&1; then
    if sudo service docker start >/dev/null 2>&1; then
      echo "Docker service started inside this project box."
      return 0
    fi
  fi

  cat >&2 <<'EOF'
WARN: Docker was installed, but the daemon is not reachable yet.
      Exit and re-enter the Distrobox, then try:
        sudo service docker start

      Nested Docker inside Distrobox may depend on host/container runtime
      settings. For genuinely messy container experiments, use a VM.
EOF
}

echo "Configuring optional Docker tooling for ${project_name}."
echo "Project mount: ${project_mount}"

install_docker_packages
configure_docker_group
try_start_docker_service

docker --version || true
docker compose version || docker-compose --version || true

echo "Docker tooling is installed inside this project Distrobox only."
