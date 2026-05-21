#!/usr/bin/env bash
# Start/check the Docker daemon inside one project Distrobox.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/start-project-docker.sh <project-name> [--dry-run]

Starts the Docker daemon inside a project Distrobox created with --with-docker.
This may prompt for sudo inside the project box.
EOF
}

project_name=""

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

project_name="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n)
      export WS_DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

box_name="$(project_box_name "$project_name")"

section "Project Docker daemon"
log "Project: ${project_name}"
log "Distrobox: ${box_name}"

if ! command_exists distrobox-enter && [[ "${WS_DRY_RUN}" != "1" ]]; then
  die "distrobox-enter is not installed. Run ./bootstrap.sh first."
fi

if [[ "${WS_DRY_RUN}" != "1" ]] && ! distrobox_exists "$box_name"; then
  die "Distrobox '${box_name}' does not exist."
fi

if [[ "${WS_DRY_RUN}" == "1" ]]; then
  log "Would start/check Docker inside ${box_name}."
  exit 0
fi

distrobox-enter --name "$box_name" -- bash -s <<'EOF'
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  printf 'ERROR: docker is not installed in this project box. Re-run ws-new <template> <project> --with-docker.\n' >&2
  exit 1
fi

if docker info >/dev/null 2>&1; then
  echo "Docker daemon is already reachable."
else
  if command -v service >/dev/null 2>&1; then
    echo "Starting Docker daemon with: sudo service docker start"
    sudo service docker start
  else
    printf 'ERROR: service command not found; cannot start Docker automatically in this box.\n' >&2
    exit 1
  fi
fi

for _ in 1 2 3 4 5; do
  if docker info >/dev/null 2>&1; then
    docker --version
    docker compose version || docker-compose --version || true
    echo "Docker daemon is reachable."
    exit 0
  fi
  sleep 1
done

if sudo docker info >/dev/null 2>&1; then
  printf 'ERROR: Docker is running, but this user cannot access /var/run/docker.sock.\n' >&2
  printf '       Exit and re-enter the project Distrobox so docker group membership refreshes.\n' >&2
  exit 1
fi

printf 'ERROR: Docker daemon still is not reachable at /var/run/docker.sock.\n' >&2
printf '       Nested Docker in Distrobox can depend on host runtime details.\n' >&2
exit 1
EOF
