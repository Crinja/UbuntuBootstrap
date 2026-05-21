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

Open a project with project-local Code state:

```bash
ws-code ExampleProject
```

Project-local Code state should appear under:

```text
~/Boxes/projects/ExampleProject/.vscode-flatpak/user-data
~/Boxes/projects/ExampleProject/.vscode-flatpak/extensions
```

For projects created with `--with-devcontainer` or `--with-podman`, the Dev
Containers extension is installed into that project-local extensions directory
when `ws-code` opens the project.

The integrated terminal should default to `Project Distrobox`. Check inside a
new VS Code terminal:

```bash
pwd
command -v cargo node python3
```

If the terminal starts on the host, rerun:

```bash
ws-code ExampleProject
```

That rewrites the project-local VS Code terminal profile. The terminal profile
uses `flatpak-spawn --host`, so the VS Code Flatpak must be allowed to talk to
the host Flatpak portal. `install-flatpaks.sh` applies that VS Code override
when `com.visualstudio.code` is in `config/flatpaks.txt`.

If the Dev Containers extension cannot find the container runtime in a project
that should use host Podman, rerun:

```bash
ws-new node ExampleProject --with-podman
ws-code ExampleProject
```

That creates this marker and lets `ws-code` write bridge settings:

```text
~/Boxes/projects/ExampleProject/.vscode-flatpak/enable-host-podman
```

To confirm host Podman works:

```bash
podman info
podman run --rm hello-world
```

If `ws-code` says VS Code is not installed, run:

```bash
./scripts/install-flatpaks.sh
```

If an extension needs direct access to a compiler, debugger, or language server
inside a container, prefer a devcontainer for that repo or configure the
extension to call the relevant `distrobox-enter` command explicitly.

## Podman Dev Containers

Dev Containers use host rootless Podman. For a generated template:

```bash
ws-new node WebApp --with-devcontainer
```

For an existing repo that already has `.devcontainer/`:

```bash
ws-new generic WebApp --with-podman
ws-code WebApp
```

If compose-based devcontainers fail, check the host helper:

```bash
command -v podman-compose
```

Install it through the bootstrap package list or manually:

```bash
sudo apt install podman-compose
```

Use a VM if a repo needs unusual daemon, kernel, networking, or privileged
behavior.

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
