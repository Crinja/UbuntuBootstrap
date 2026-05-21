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

docker_info_as_user() {
  docker info >/dev/null 2>&1
}

docker_info_with_sudo() {
  sudo docker info >/dev/null 2>&1
}

wait_for_docker() {
  local attempt

  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if docker_info_as_user || docker_info_with_sudo; then
      return 0
    fi
    sleep 1
  done

  return 1
}

start_docker_with_systemctl() {
  command -v systemctl >/dev/null 2>&1 || return 1
  systemctl list-unit-files docker.service >/dev/null 2>&1 || return 1
  sudo systemctl start docker >/dev/null 2>&1
}

start_docker_with_service() {
  command -v service >/dev/null 2>&1 || return 1
  [[ -x /etc/init.d/docker ]] || return 1
  sudo service docker start >/dev/null 2>&1
}

start_docker_with_dockerd() {
  command -v dockerd >/dev/null 2>&1 || return 1

  sudo mkdir -p /var/lib/docker /var/log /var/run
  sudo rm -f /var/run/docker.pid
  sudo sh -c 'nohup dockerd --host=unix:///var/run/docker.sock --pidfile=/var/run/docker.pid > /var/log/dockerd-project.log 2>&1 &'
}

try_start_docker_daemon() {
  if docker info >/dev/null 2>&1; then
    echo "Docker daemon is already reachable."
    return 0
  fi

  if docker_info_with_sudo; then
    echo "Docker daemon is reachable with sudo."
    echo "Exit and re-enter the Distrobox so docker group membership refreshes."
    return 0
  fi

  if start_docker_with_systemctl; then
    echo "Docker daemon started with systemctl."
  elif start_docker_with_service; then
    echo "Docker daemon started with service."
  elif start_docker_with_dockerd; then
    echo "Docker daemon started directly with dockerd."
  else
    echo "WARN: Could not find a usable systemctl, service, or dockerd start path." >&2
  fi

  if wait_for_docker; then
    if docker_info_as_user; then
      echo "Docker daemon is reachable."
    else
      echo "Docker daemon is reachable with sudo."
      echo "Exit and re-enter the Distrobox so docker group membership refreshes."
    fi
    return 0
  fi

  cat >&2 <<'EOF'
WARN: Docker was installed, but the daemon is not reachable yet.
      Try from the host:
        ws-docker-start <project-name>

      Nested Docker inside Distrobox may depend on host/container runtime
      settings. For genuinely messy container experiments, use a VM.

      If dockerd was attempted, inspect:
        sudo tail -n 80 /var/log/dockerd-project.log
EOF
}

echo "Configuring optional Docker tooling for ${project_name}."
echo "Project mount: ${project_mount}"

install_docker_packages
configure_docker_group
try_start_docker_daemon

docker --version || true
docker compose version || docker-compose --version || true

echo "Docker tooling is installed inside this project Distrobox only."
