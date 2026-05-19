# Troubleshooting

## PATH

```bash
./scripts/install-shell-integration.sh
source ~/.bashrc
command -v ws-new
```

## Flatpak

VS Code is installed by default from `config/flatpaks.txt`. To install more
apps, add their IDs to that file, then run:

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

Check the VS Code Flatpak:

```bash
flatpak info com.visualstudio.code
```

Open a project with its profile:

```bash
ws-code ExampleProject
```

If `ws-code` says VS Code is not installed, run:

```bash
./scripts/install-flatpaks.sh
```

If an extension needs direct access to a compiler, debugger, or language server
inside a container, prefer a devcontainer for that repo or configure the
extension to call the relevant `distrobox-enter` command explicitly.

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

AI auth/config is project-local and lives inside the selected project box home,
for example:

```text
~/Boxes/projects/ExampleProject/.claude
~/Boxes/projects/ExampleProject/.claude.json
~/Boxes/projects/ExampleProject/.codex
```

If an older project has `~/.claude`, `~/.claude.json`, or `~/.codex` symlinked
to `/work/ai-state`, rerun `ws-ai-add ExampleProject --claude`, `--codex`, or
`--all`. The setup script localizes those legacy links into the project home.

If Claude prints:

```text
claude configuration file not found at: ~/.claude.json
A backup file exists at: ~/.claude/backups/.claude.json.backup.<timestamp>
```

repair the project state by re-running:

```bash
ws-ai-add ExampleProject --claude
```

The setup script restores the newest project-local Claude backup when available
or creates a minimal local `~/.claude.json`.

## VM Instead

Use a VM for untrusted software, Windows-only tools, kernel modules, or anything
that should not share the user session.
