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
- Podman and Distrobox.
- VM/snapshot tools.
- `ws-*` shell helpers.

AI state:

- Shared Claude state lives under `~/Boxes/ai-state/claude`.
- Shared Codex state lives under `~/Boxes/ai-state/codex`.
- Claude Code and Codex CLI are not installed by default.

Project boxes:

```bash
ws-new rust ExampleProject
ws-enter ExampleProject
ws-code ExampleProject
```

VS Code is installed inside new project boxes by default. Skip it with
`--no-ide` for tiny or headless environments.

Docker is opt-in per project for devcontainer-heavy repos:

```bash
ws-new node WebApp --with-devcontainer --with-docker
```

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

`config/flatpaks.txt` is intentionally empty. The installer configures Flathub
but installs no apps until I add app IDs.

## Common Commands

```bash
ws-new rust ExampleProject
ws-new node CSIT314-TalentMatching
ws-new dotnet HackJack --with-devcontainer --with-docker
ws-new python HeadlessScript --no-ide
ws-new rust AgentProject --with-claude

ws-enter ExampleProject
ws-code ExampleProject
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
state is shared through `~/Boxes/ai-state`.

## Layout

```text
~/Projects/<project>
~/Boxes/projects/<project>
~/Boxes/ai-state/claude
~/Boxes/ai-state/codex
~/VMs
~/Scratch
~/Downloads/Quarantine
```

## Notes

- No Rust, Node, .NET SDKs, databases, or project CLIs on the host.
- No VS Code on the host.
- No Docker on the host by default; use Podman on the host and `--with-docker`
  only for project boxes that need it.
- No Claude Code or Codex CLI on the host. Add them per project with
  `--with-claude`, `--with-codex`, `--with-ai`, or `ws-ai-add`.
- GUI apps should usually be Flatpaks, but none are installed by default.
- Distrobox is for cleanliness and workflow separation, not malware isolation.
- Use a VM for genuinely untrusted or weird system-level software.
