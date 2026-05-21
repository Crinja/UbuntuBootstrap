# Ubuntu Bootstrap

Private bootstrap notes for my Ubuntu workstation.

The host is a management OS. It gets enough tooling to run the machine, manage
containers/VMs, install optional Flatpaks, and launch project environments. Real
development tooling lives in per-project Distroboxes.

Rule:

> If it is not needed to run the machine itself, it does not belong on the host.

## Bootstrap

Fresh VM first:

```bash
sudo apt update
sudo apt install -y git
git clone <repo-url> UbuntuBootstrap
cd UbuntuBootstrap
bash ./bootstrap.sh
```

Then open a new terminal, or:

```bash
source ~/.bashrc
```

Dry run:

```bash
bash ./bootstrap.sh --dry-run
```

## Defaults

Host installs:

- Basic CLI/system tools.
- Flatpak and Flathub support.
- VS Code as a Flatpak GUI app.
- Podman and Distrobox.
- VM/snapshot tools.
- `ws-*` shell helpers.

AI tools:

- Claude Code and Codex CLI are not installed by default.
- When enabled, each project keeps its own AI config in its own Distrobox home.
- There is no shared Claude/Codex settings folder.

Project boxes:

```bash
ws-new rust ExampleProject
ws-enter ExampleProject
ws-code ExampleProject
```

`ws-code` launches the VS Code Flatpak against `~/Projects/<project>` with
project-specific Code state under `~/Boxes/projects/<project>/.vscode-flatpak`.
Extensions installed from that window stay out of the normal default Code
state. The integrated terminal defaults to the matching project Distrobox.
If the project was created with `--with-docker`, `ws-code` also points the Dev
Containers extension at that project Distrobox's Docker CLI.

Docker is opt-in per project for devcontainer-heavy repos:

```bash
ws-new node WebApp --with-devcontainer --with-docker
```

That installs Docker/Compose inside `project-webapp` and enables the
project-local VS Code bridge for Dev Containers. Docker-enabled boxes are
created with extra init/privileged container settings because they run a nested
daemon; keep that opt-in for trusted repos.

AI tools are also opt-in per project:

```bash
ws-new rust AgentProject --with-claude
ws-new node AgentWeb --with-ai
ws-ai-add ExampleProject --codex
```

Creates:

```text
~/Projects/ExampleProject
~/Boxes/projects/ExampleProject
project-exampleproject
```

Flatpaks:

`config/flatpaks.txt` installs VS Code by default. Other desktop apps stay
manual until I add their app IDs.

## Common Commands

```bash
ws-new rust ExampleProject
ws-new node WebExample
ws-new dotnet ApiExample --with-devcontainer --with-docker
ws-new python HeadlessScript
ws-new rust AgentProject --with-claude

ws-enter ExampleProject
ws-code ExampleProject
ws-docker-start ExampleProject
ws-list
ws-remove ExampleProject
```

AI tools:

```bash
ws-ai-add ExampleProject --claude
ws-enter ExampleProject
claude
codex
```

Claude and Codex run directly inside the selected project Distrobox. Auth/config
state stays local to that project's Distrobox home.

## Layout

```text
~/Projects/<project>
~/Boxes/projects/<project>
~/VMs
~/Scratch
~/Downloads/Quarantine
```

## Notes

- No Rust, Node, .NET SDKs, databases, or project CLIs on the host.
- No VS Code apt/deb on the host and no VS Code inside every Distrobox. VS Code
  lives as a Flatpak GUI app.
- No Docker on the host by default; use Podman on the host and `--with-docker`
  only for project boxes that need it.
- No Claude Code or Codex CLI on the host. Add them per project with
  `--with-claude`, `--with-codex`, `--with-ai`, or `ws-ai-add`.
- GUI apps should usually be Flatpaks. VS Code is included by default; other
  apps stay manual until I add them to `config/flatpaks.txt`.
- Distrobox is for cleanliness and workflow separation, not malware isolation.
- Use a VM for genuinely untrusted or weird system-level software.
