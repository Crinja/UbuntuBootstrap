# Troubleshooting

## Flathub Not Added

Run:

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remotes
```

Then rerun:

```bash
./scripts/install-flatpaks.sh
```

## Flatpak Apps Do Not Appear

Log out and back in, or reboot. Desktop launchers sometimes appear only after
the session refreshes.

## Podman Rootless Issues

Check:

```bash
podman info
```

If rootless storage or user namespace errors appear, reboot after installing
Podman. On unusual systems, verify `/etc/subuid` and `/etc/subgid` contain an
entry for your user.

## Distrobox Creation Failures

Check:

```bash
podman info
distrobox-list
```

Then try creating a small test box:

```bash
distrobox-create --name test-box --image ubuntu:24.04 --yes
```

If image pulls fail, check network access and registry availability.

## Project Environment Creation Failures

Run:

```bash
ws-list
distrobox-list
```

If the Distrobox exists but template setup failed, rerun:

```bash
ws-new <template> <project-name>
```

Templates are designed to be idempotent.

## PATH Does Not Find ws-new or ws-enter

Add the Bash snippet:

```bash
echo "source \"/path/to/linux-workstation/dotfiles/bashrc.append\"" >> ~/.bashrc
source ~/.bashrc
```

Use the real path where this repo is cloned. Confirm:

```bash
command -v ws-new
command -v ws-enter
```

## NVIDIA and GPU Caveats

GPU support depends on the host driver stack. Flatpak, Distrobox, Steam, and
VMs each have their own integration details. If GPU workloads fail, first
confirm the host driver works outside containers.

## Steam and Gaming Caveats

Steam Flatpak is a good default for host cleanliness and is included in
`config/flatpaks.txt`.

Gaming inside Distrobox can work, but compatibility varies. Anti-cheat, Proton,
controller support, and GPU integration may behave differently than a normal
host install.

## When To Use a VM Instead

Use a VM for:

- Genuinely untrusted software.
- Windows-only tools.
- Kernel modules or low-level system changes.
- Malware-adjacent analysis.
- Experiments that might damage a user session.

Distrobox is for contamination control and workflow separation, not strong
malware isolation.
