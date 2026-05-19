# Troubleshooting

## PATH

```bash
./scripts/install-shell-integration.sh
source ~/.bashrc
command -v ws-new
```

## Flatpak

The default app list is empty. To install apps, add IDs to
`config/flatpaks.txt`, then run:

```bash
./scripts/install-flatpaks.sh
```

Check Flathub:

```bash
flatpak remotes
```

## Podman / Distrobox

```bash
podman info
distrobox-list
distrobox-create --name test-box --image ubuntu:24.04 --yes
```

If rootless Podman behaves strangely after install, reboot once.

## Project Boxes

If template setup failed, rerun the same command:

```bash
ws-new rust ExampleProject
```

Templates should be idempotent.

## VS Code

Check Code inside the selected box:

```bash
distrobox-enter --name project-exampleproject -- command -v code
```

For a manually created editor box:

```bash
ws-code --box <box-name>
```

## Docker In Project Boxes

Docker is not installed in every project box. Add it only when needed:

```bash
ws-new node WebApp --with-devcontainer --with-docker
```

Check it inside the project box:

```bash
ws-enter WebApp
docker --version
docker compose version
```

If Docker was installed but the daemon is not reachable, exit and re-enter the
box. If it still fails:

```bash
sudo service docker start
```

Nested Docker in Distrobox can depend on host runtime details. Use a VM if a
repo needs unusual daemon, kernel, networking, or privileged behavior.

## AI Tools

Repair the AI tool boxes:

```bash
ws-ai-setup
distrobox-enter --name claude-code -- bash -lc 'command -v claude'
distrobox-enter --name codex -- bash -lc 'command -v codex'
```

Check the project shell directly:

```bash
ws-enter ExampleProject
pwd
command -v claude
command -v codex
cargo --version
command -v distrobox-host-exec
```

Check the AI wrappers:

```bash
ws-claude ExampleProject --help
ws-codex ExampleProject --help
```

Check host integration from the tool boxes:

```bash
distrobox-enter --name claude-code -- bash -lc 'command -v distrobox-host-exec && distrobox-host-exec --yes true'
distrobox-enter --name codex -- bash -lc 'command -v distrobox-host-exec && distrobox-host-exec --yes true'
```

Do not install the Ubuntu `distrobox` package inside the AI tool boxes. It can
conflict with Distrobox-managed files injected from the host.

If I accidentally tried that and dpkg is wedged:

```bash
distrobox-enter --name claude-code -- bash -lc 'sudo dpkg --remove --force-remove-reinstreq distrobox 2>/dev/null || true; sudo apt-get -f install; sudo dpkg --configure -a'
distrobox-enter --name codex -- bash -lc 'sudo dpkg --remove --force-remove-reinstreq distrobox 2>/dev/null || true; sudo apt-get -f install; sudo dpkg --configure -a'
```

## VM Instead

Use a VM for untrusted software, Windows-only tools, kernel modules, or anything
that should not share the user session.
