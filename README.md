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

Tool boxes:

- `claude-code` for Claude Code.
- `codex` for Codex CLI.

No other always-on Distroboxes are created. Extra task boxes can be added
manually later when I actually need them.

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

ws-enter ExampleProject
ws-code ExampleProject
ws-list
ws-remove ExampleProject
```

AI tools:

```bash
ws-ai-setup
ws-claude ExampleProject
ws-codex ExampleProject
```

`ws-enter`, `ws-claude`, and `ws-codex` inject `~/.local/share/ws-ai/bin` into
the project shell PATH. That bin provides lightweight `claude` and `codex`
wrappers. The real AI auth state stays in `claude-code` or `codex`, while shell
commands run through the project box.

## Layout

```text
~/Projects/<project>
~/Boxes/projects/<project>
~/Boxes/claude-code
~/Boxes/codex
~/VMs
~/Scratch
~/Downloads/Quarantine
```

## Notes

- No Rust, Node, .NET SDKs, databases, or project CLIs on the host.
- No VS Code on the host.
- No Docker on the host by default; use Podman on the host and `--with-docker`
  only for project boxes that need it.
- GUI apps should usually be Flatpaks, but none are installed by default.
- Distrobox is for cleanliness and workflow separation, not malware isolation.
- Use a VM for genuinely untrusted or weird system-level software.
