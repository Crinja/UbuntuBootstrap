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

Templates install the shared editor/Git baseline first, then optional language
tooling for that project only.

VS Code is installed by default inside each project box:

```bash
ws-new rust ExampleProject
```

Skip it when I want a smaller environment:

```bash
ws-new python HeadlessScript --no-ide
```

Docker is opt-in for repos that need devcontainers or Docker Compose:

```bash
ws-new node WebApp --with-devcontainer --with-docker
```

That installs Docker/Compose tooling inside that project Distrobox only.

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
