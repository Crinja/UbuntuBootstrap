# Philosophy

This setup keeps the host boring.

The host manages the desktop, hardware, Flatpak support, Podman/Distrobox, VMs,
snapshots, and shell helpers. Project SDKs and one-off tools live somewhere else.

Layers:

- Host: management plane only.
- Flatpak: optional GUI apps.
- Project Distrobox: normal development work.
- Project Docker: opt-in only, for repos that need devcontainers or Compose.
- `claude-code`: Claude Code box.
- `codex`: Codex CLI box.
- VM: untrusted, incompatible, or system-level experiments.

Flatpak app installation is opt-in. `config/flatpaks.txt` starts empty.

Distrobox keeps the host clean, but it is not a hard security boundary.
