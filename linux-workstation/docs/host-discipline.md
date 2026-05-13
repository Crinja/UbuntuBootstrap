# Host Discipline

The host is the management OS. Keep it small, boring, and recoverable.

## Belongs on the Host

- Drivers and hardware integration.
- Desktop tools and GNOME integration.
- File tools and archive tools.
- Backup and snapshot tools such as Timeshift.
- Flatpak and Flatseal.
- Podman.
- Distrobox.
- VM tools such as GNOME Boxes and virt-manager.
- A basic editor or terminal if desired.
- Diagnostics such as `htop`, `btop`, `tree`, `jq`, `ripgrep`, and `shellcheck`.

## Does Not Belong on the Host

- Rust toolchains.
- Node/npm.
- .NET SDKs.
- Databases such as MongoDB, Postgres, MySQL, or Redis.
- Random language package managers.
- Global pip/npm/cargo tools.
- Project-specific CLIs.
- Experimental libraries.
- Uni-specific junk that belongs to one course or assignment.

## Rule of Thumb

If uninstalling a project would require cleaning host packages, the project was
probably installed at the wrong layer.
