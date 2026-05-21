# Host Discipline

Host allowed:

- Drivers and hardware support.
- GNOME/desktop integration.
- Backup/snapshot tools.
- Flatpak support.
- Podman and Distrobox.
- VM tools.
- Basic CLI tools.
- A small terminal editor.
- VS Code as a Flatpak GUI app.

Host not allowed:

- Rust, Node, .NET, Java SDKs.
- Databases and queues.
- VS Code installed through host apt/deb or copied into every project box.
- Claude Code or Codex CLI on the host.
- Global pip/npm/cargo tools.
- Project-specific CLIs.
- Experimental libraries.

If deleting a project requires host package cleanup, I put something in the
wrong layer.

Host Podman is allowed because it is the container runtime used by Distrobox
and VS Code Dev Containers.

Claude Code and Codex CLI are only installed inside a project Distrobox when I
pass `--with-claude`, `--with-codex`, `--with-ai`, or run `ws-ai-add`.
