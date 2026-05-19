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

Add an AI tool to a project:

```bash
ws-ai-add ExampleProject --claude
ws-ai-add ExampleProject --codex
```

Check the project shell:

```bash
ws-enter ExampleProject
pwd
command -v claude
command -v codex
cargo --version
```

Run the project-local tools after entering the project:

```bash
ws-enter ExampleProject
claude --help
codex --help
```

If `ws-ai-add` says `/work/ai-state` is missing, the project box was probably
created before shared AI state was added. Recreate the project box with the
current `ws-new` script or manually mount `~/Boxes/ai-state` at `/work/ai-state`.

Shared auth/config state is under `~/Boxes/ai-state`.

If Claude prints:

```text
claude configuration file not found at: ~/.claude.json
A backup file exists at: ~/.claude/backups/.claude.json.backup.<timestamp>
```

repair the project state by re-running:

```bash
ws-ai-add ExampleProject --claude
```

The setup script links `~/.claude.json` to the shared Claude state file and, if
that shared file does not exist yet, restores the newest Claude backup. If it
warns that `~/.claude` or `~/.claude.json` already exists and was not replaced,
move the local file or directory aside manually before re-running the command.

## VM Instead

Use a VM for untrusted software, Windows-only tools, kernel modules, or anything
that should not share the user session.
