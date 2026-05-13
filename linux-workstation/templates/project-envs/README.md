# Project Environment Templates

These scripts run inside a project Distrobox created by `ws-new`.

They are allowed to install language tooling because the tooling is scoped to
one project environment:

- `rust.sh` installs Rust with rustup inside the box.
- `node.sh` installs Node through nvm inside the box.
- `python.sh` installs Python basics and encourages a project-local `.venv`.
- `dotnet.sh` installs prerequisites and leaves a clear TODO for the pinned SDK.
- `php.sh` installs conservative PHP CLI tooling.
- `generic.sh` installs a minimal Linux build baseline.

Keep templates idempotent. Re-running `ws-new rust Terrakit` should not destroy
or overwrite project source files.

Distrobox helps keep the host clean, but it is not a hard security boundary.
Use a VM for genuinely untrusted software.
