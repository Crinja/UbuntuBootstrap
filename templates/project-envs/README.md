# Project Environment Templates

These scripts run inside a project Distrobox created by `ws-new`.

`_dev-base.sh` is prepended automatically by `ws-new`. It installs the editor
and workflow baseline inside the project box:

- VS Code
- Git/Git LFS
- SSH client
- ripgrep/fd/jq/tree
- shellcheck
- basic archive and desktop integration tools

It deliberately does not install language SDKs.

AI coding tools are handled by the shared `ai-code` base box, not by project
templates. Use `ws-ai-setup`, `ws-claude`, and `ws-codex`. The launch wrappers
expose project Distrobox SDK tools into the `ai-code` session through a temporary
tool bridge.

Language templates are allowed to install tooling because the tooling is scoped
to one project environment:

- `rust.sh` installs Rust with rustup inside the box.
- `rust-nightly.sh` installs nightly Rust with rustup inside the box.
- `cpp.sh` installs a conservative C/C++ compiler and debugger set.
- `csharp.sh` prepares a C#/.NET project and can optionally install a requested SDK package.
- `java.sh` installs OpenJDK 21 plus Maven/Gradle basics.
- `js.sh` and `node.sh` install Node through nvm inside the box.
- `python.sh` installs Python basics and encourages a project-local `.venv`.
- `dotnet.sh` installs prerequisites and leaves a clear TODO for the pinned SDK.
- `php.sh` installs conservative PHP CLI tooling.
- `generic.sh` installs the base dev layer plus minimal generic packages.

Keep templates idempotent. Re-running `ws-new rust Terrakit` should not destroy
or overwrite project source files.

Keep agent credentials out of Git. AI agent state lives in `~/Boxes/ai-code`,
but project `.env` files can still be committed by mistake if you are careless.

Distrobox helps keep the host clean, but it is not a hard security boundary.
Use a VM for genuinely untrusted software.
