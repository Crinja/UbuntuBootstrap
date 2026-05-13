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
- Creates broad base Distroboxes: `uni-work`, `gaming`, and `experimental`.
- Provides project-scoped environment tooling:
  - `ws-new rust Terrakit`
  - `ws-enter Terrakit`
  - `ws-list`
  - `ws-remove Terrakit`
- Optionally generates `.devcontainer` folders per project.
- Includes an optional `installer/autoinstall.example.yaml` for VM-first Ubuntu
  installs.

## What This Deliberately Does Not Do

- It does not install Rust, Node, .NET SDKs, databases, or project CLIs on the host.
- It does not create broad long-lived `dev-rust`, `dev-node`, or `dev-dotnet` boxes.
- It does not repartition disks, configure disk encryption, or delete user data.
- It does not run `autoinstall.yaml` or automate OS installation from bootstrap.
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
echo "source \"$(pwd)/dotfiles/bashrc.append\"" >> ~/.bashrc
source ~/.bashrc
ws-new rust Terrakit
ws-enter Terrakit
```

For the detailed checklist, see `docs/vm-test-plan.md`.

An optional installer template is available at
`installer/autoinstall.example.yaml`. It keeps storage, identity, and network
interactive by default because autoinstall can wipe disks if made fully
non-interactive.

## Real Machine Install

After testing in a VM:

```bash
sudo apt update
sudo apt install -y git
git clone <your-repo-url> linux-workstation
cd linux-workstation
bash ./bootstrap.sh
echo "source \"$(pwd)/dotfiles/bashrc.append\"" >> ~/.bashrc
source ~/.bashrc
```

If executable bits are preserved in your clone, `./bootstrap.sh` is also fine.
Using `bash ./bootstrap.sh` works even when the executable bit was not preserved.

## Common Workflow

```bash
ws-new rust Terrakit
ws-enter Terrakit

ws-new dotnet HackJack --with-devcontainer
ws-enter HackJack

ws-new node CSIT314-TalentMatching
ws-enter CSIT314-TalentMatching

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
tools, rollback tools, file tools, and a basic editor or terminal.

Use Flatpak for GUI apps such as Discord, Spotify, VLC, Obsidian, GIMP,
LibreOffice, Steam, and Flatseal.

Use a project Distrobox for serious development work. Each project gets its own
box, custom home, source folder, and toolchain.

Use a base Distrobox for broad task categories that are not specific software
stacks: `uni-work`, `gaming`, and `experimental`.

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

- `uni-work`
- `gaming`
- `experimental`

They are not language environments and should not become dumping grounds for
every SDK.

Project boxes are preferred for development because they give each repository
proper control over its own tooling. A Rust game, a .NET API, and a Node
coursework project should not share one long-lived global development box.

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
