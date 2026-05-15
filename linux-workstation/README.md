# Ubuntu Workstation Bootstrap

This repository bootstraps a clean Ubuntu workstation where the host stays
minimal and serious development tooling lives in isolated project environments.

Host discipline rule:

> If it is not needed to run the machine itself, it does not belong on the host.

The intended host is Ubuntu 24.04 LTS or newer with GNOME. The scripts are Bash,
Podman is preferred over Docker for rootless local containers, Distrobox is used
for project/task environments, Flatpak is used for desktop apps, and Timeshift
is included for host rollback.

## What This Does

- Installs a small set of host management packages from `config/host-packages.txt`.
- Configures Flatpak and Flathub.
- Installs desktop apps from `config/flatpaks.txt`.
- Creates a predictable folder layout under your home directory.
- Creates broad base Distroboxes: `ai-code`, `dev-base`, and `experimental`.
- Configures the shared `ai-code` box with Claude Code and Codex CLI.
- Provides project-scoped environment tooling:
  - `ws-new rust Terrakit`
  - `ws-enter Terrakit`
  - `ws-code Terrakit`
  - `ws-list`
  - `ws-remove Terrakit`
- Optionally generates `.devcontainer` folders per project.

## What This Deliberately Does Not Do

- It does not install Rust, Node, .NET SDKs, databases, or project CLIs on the host.
- It does not install VS Code on the host.
- It does not install Claude Code, Codex CLI, or other AI coding agents on the host.
- It does not create broad long-lived `dev-rust`, `dev-node`, or `dev-dotnet` boxes.
- It does not repartition disks, configure disk encryption, or delete user data.
- It does not add random PPAs by default.
- It does not treat Distrobox as a malware sandbox.

## Fresh VM Test

Use a fresh Ubuntu VM before touching a real machine:

```bash
sudo apt update
sudo apt install -y git
git clone <your-repo-url> linux-workstation
cd linux-workstation
bash ./bootstrap.sh
```

Then reboot, open a terminal, and run:

```bash
./scripts/verify.sh
source ~/.bashrc
ws-new rust Terrakit
ws-enter Terrakit
```

For the detailed checklist, see `docs/vm-test-plan.md`.

## Real Machine Install

After testing in a VM:

```bash
sudo apt update
sudo apt install -y git
git clone <your-repo-url> linux-workstation
cd linux-workstation
bash ./bootstrap.sh
source ~/.bashrc
```

`bootstrap.sh` adds the `ws-*` commands to `~/.bashrc` automatically. Run
`source ~/.bashrc` in the current terminal or open a new one.

If executable bits are preserved in your clone, `./bootstrap.sh` is also fine.
Using `bash ./bootstrap.sh` works even when the executable bit was not preserved.

## Common Workflow

Configure the optional SDK-free editor box:

```bash
distrobox-enter --name dev-base -- bash -s < boxes/dev-base.sh
ws-code --base
```

The shared AI coding tools box is configured during bootstrap. To repair or
update it later:

```bash
ws-ai-setup
```

Run agents against a project:

```bash
ws-claude Terrakit
ws-codex Terrakit
```

Create project boxes:

```bash
ws-new rust Terrakit
ws-enter Terrakit
ws-code Terrakit

ws-new dotnet HackJack --with-devcontainer
ws-enter HackJack

ws-new node CSIT314-TalentMatching
ws-enter CSIT314-TalentMatching

ws-new cpp EngineExperiment
ws-code EngineExperiment

ws-new rust-nightly CompilerExperiment
ws-code CompilerExperiment

ws-list
ws-remove Terrakit
```

That creates:

```text
~/Projects/Terrakit
~/Boxes/projects/Terrakit

~/Projects/HackJack
~/Boxes/projects/HackJack

~/Projects/CSIT314-TalentMatching
~/Boxes/projects/CSIT314-TalentMatching
```

Distrobox names are normalized:

```text
Terrakit                  -> project-terrakit
HackJack                  -> project-hackjack
CSIT314-TalentMatching    -> project-csit314-talentmatching
```

## When To Use What

Use host `apt` for drivers, desktop integration, Flatpak, Podman, Distrobox, VM
tools, rollback tools, file tools, and a terminal/basic editor if desired.

Do not install VS Code on the host. VS Code belongs in `dev-base` for general
editing or inside project boxes through `ws-new`.

Use Flatpak for GUI apps such as Discord, Spotify, VLC, Obsidian, GIMP,
LibreOffice, Steam, and Flatseal.

Use Steam Flatpak for normal gaming. A Distrobox gaming setup can still be made
manually later for special cases, but it is not part of the default bootstrap.

Use a project Distrobox for serious development work. Each project gets its own
box, custom home, source folder, IDE, and toolchain.

Use `ai-code` for Claude Code and Codex CLI. It is a single shared Distrobox
outside the host with `~/Projects` mounted at `/work/projects`, so you configure
agent auth once and point it at whichever project you are working on:

```bash
ws-claude Terrakit
ws-codex Terrakit
```

Use a base Distrobox for broad task categories that are not specific software
stacks: `ai-code`, `dev-base`, and `experimental`. `dev-base` is the SDK-free
editor/Git box. `ai-code` is the shared AI coding tools box.

Use devcontainers when a repository needs editor-integrated reproducibility or
when collaborators already expect `.devcontainer`.

Use Docker/Podman Compose inside a project when the project needs services such
as databases, queues, or multiple app containers. Keep compose files in the
project repository.

Use VMs for genuinely untrusted software, Windows-only tools, malware-adjacent
experiments, kernel work, or anything that needs a stronger boundary than
Distrobox.

## Base Boxes vs Project Boxes

Base boxes are broad work areas:

- `dev-base`
- `ai-code`
- `experimental`

They are not language environments and should not become dumping grounds for every
SDK. `dev-base` is allowed to contain VS Code, Git, SSH, and command-line basics.
`ai-code` is allowed to contain Claude Code, Codex CLI, and their Node runtime.
Neither should contain Rust, project Node stacks, .NET SDKs, JDKs, databases, or
project CLIs.

Project boxes are preferred for development because they give each repository
proper control over its own tooling. A Rust game, a .NET API, and a Node
coursework project should not share one long-lived global development box.

Project templates build on the same base development layer as `dev-base`, then
add project-specific tooling such as Rust, C++, Java, Node, Python, or C#.

## Security Boundary Notes

Distrobox is excellent for contamination control and workflow separation. It can
keep dotfiles, package installs, SDKs, and experiments away from the host apt
layer.

It is not a hard malware isolation boundary. For hostile or genuinely untrusted
software, use a VM.

Flatpak is the default for GUI apps because it keeps desktop applications out of
the host package layer and pairs well with Flatseal for permission review.

## Dry Run

Most setup scripts support dry-run mode:

```bash
bash ./bootstrap.sh --dry-run
./scripts/create-project-env.sh rust Terrakit --dry-run
```

Dry-run mode prints intended commands. It does not guarantee every future
package will be available from your configured repositories.
