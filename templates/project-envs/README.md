# Project Templates

These scripts run inside project Distroboxes created by `ws-new`.

`_project-baseline.sh` runs first and installs the editor/Git baseline. Language
templates then add project-specific tooling inside that one box.

VS Code is part of the baseline by default. Use `--no-ide` to skip it.

`_docker.sh` is optional and runs only when `ws-new` receives `--with-docker`.

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
