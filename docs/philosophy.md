# Philosophy

This setup keeps the host boring.

The host manages the desktop, hardware, Flatpak support, Podman/Distrobox, VMs,
snapshots, and shell helpers. Project SDKs and one-off tools live somewhere else.

Layers:

- Host: management plane only.
- Flatpak: GUI apps, including VS Code.
- Project Distrobox: normal development work.
- Host Podman: rootless runtime for Distrobox and Dev Containers.
- Project AI tools: opt-in Claude/Codex installs inside project boxes.
- VM: untrusted, incompatible, or system-level experiments.

VS Code is installed as a Flatpak. Other Flatpak apps are opt-in through
`config/flatpaks.txt`.

Distrobox keeps the host clean, but it is not a hard security boundary.
