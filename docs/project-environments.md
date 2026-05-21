# Project Environments

Each serious project gets one Distrobox.

Example:

```bash
ws-new rust ExampleProject
```

Creates:

```text
~/Projects/ExampleProject
~/Boxes/projects/ExampleProject
project-exampleproject
```

Inside the box:

```text
/work/exampleproject
~/project
```

Names are normalized for Distrobox:

```text
ExampleProject -> project-exampleproject
WebExample -> project-webexample
```

Common flow:

```bash
ws-new rust ExampleProject
ws-enter ExampleProject
ws-code ExampleProject
```

Templates install the shared Git/workflow baseline first, then optional language
tooling for that project only.

Project boxes do not install VS Code. `ws-code` opens the source folder with
the VS Code Flatpak and project-specific Code state:

```bash
ws-new rust ExampleProject
ws-code ExampleProject
```

The project Distrobox still owns the toolchain; `ws-code` stores editor
settings and extensions under `~/Boxes/projects/<project>/.vscode-flatpak`.
Its integrated terminal defaults to the matching `project-<name>` Distrobox.
If the project uses `--with-devcontainer` or `--with-podman`, `ws-code` also
writes project-local Dev Containers settings that use host rootless Podman and
installs the Dev Containers extension into that project's VS Code extension
directory.

Podman-backed Dev Containers are opt-in:

```bash
ws-new node WebApp --with-devcontainer
```

That copies a `.devcontainer/` template and enables the VS Code bridge to host
Podman for that project. Existing repos that already have `.devcontainer/` can
use `--with-podman` instead.

Claude Code and Codex CLI are also opt-in per project:

```bash
ws-new rust AgentProject --with-claude
ws-new node AgentWeb --with-ai
ws-ai-add ExampleProject --codex
```

AI auth/config state stays inside that project's Distrobox home. The CLI
binaries also live inside whichever project boxes I explicitly enable.

Available templates:

- `rust`
- `rust-nightly`
- `cpp`
- `csharp` / `dotnet`
- `java`
- `node` / `js`
- `python`
- `php`
- `generic`

Remove an environment:

```bash
ws-remove ExampleProject
```

The source folder is preserved by default.
