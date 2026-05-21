# Project Templates

These scripts run inside project Distroboxes created by `ws-new`.

`_project-baseline.sh` runs first and installs the Git/workflow baseline.
Language templates then add project-specific tooling inside that one box.

VS Code is not installed inside project boxes. Use `ws-code <project>` to open
the source folder in the VS Code Flatpak with project-specific settings and
extensions under `~/Boxes/projects/<project>/.vscode-flatpak`. Its integrated
terminal is configured to enter the matching project Distrobox. Projects created
with `--with-devcontainer` or `--with-podman` also get project-local VS Code
settings that use host Podman for Dev Containers, and `ws-code` installs the
Dev Containers extension into that project's extension directory.

`_ai-tools.sh` is optional and runs only when `ws-new` receives
`--with-claude`, `--with-codex`, or `--with-ai`, or when `ws-ai-add` is used.

Templates:

- `rust`
- `rust-nightly`
- `cpp`
- `csharp` / `dotnet`
- `java`
- `node` / `js`
- `python`
- `php`
- `generic`

Rules:

- Keep scripts idempotent.
- Do not install SDKs on the host.
- Do not overwrite project source files.
- Keep agent credentials and `.env` files out of Git.
