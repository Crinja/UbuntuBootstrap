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
CSIT314-TalentMatching -> project-csit314-talentmatching
```

Common flow:

```bash
ws-new rust ExampleProject
ws-enter ExampleProject
ws-code ExampleProject
```

Templates install the shared Git/workflow baseline first, then optional language
tooling for that project only.

Project boxes do not install VS Code. `ws-code` opens the source folder with the
VS Code Flatpak and a project-specific profile:

```bash
ws-new rust ExampleProject
ws-code ExampleProject
```

The project Distrobox still owns the toolchain; VS Code profiles own editor
extensions and UI settings.

Docker is opt-in for repos that need devcontainers or Docker Compose:

```bash
ws-new node WebApp --with-devcontainer --with-docker
```

That installs Docker/Compose tooling inside that project Distrobox only.

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
