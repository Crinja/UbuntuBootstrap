# Project Environments

Each serious project gets its own environment. This avoids the slow drift toward
a host full of global SDKs, package managers, databases, and one-off CLIs.

## Naming

Project names are preserved for folders and normalized for Distrobox names:

```text
Terrakit               -> project-terrakit
HackJack               -> project-hackjack
CSIT314-TalentMatching -> project-csit314-talentmatching
```

Normalization lowercases the name and replaces unsupported characters with
hyphens.

## Folder Layout

Source files:

```text
~/Projects/<project-name>
```

Custom Distrobox home:

```text
~/Boxes/projects/<project-name>
```

Inside the Distrobox, the project is mounted at:

```text
/work/<normalized-project-name>
~/project
```

## Create a Rust Environment

```bash
ws-new rust Terrakit
ws-enter Terrakit
```

The Rust template installs build tools and rustup inside `project-terrakit`.
Rust is not installed on the host.

## Create a Node Environment

```bash
ws-new node CSIT314-TalentMatching
ws-enter CSIT314-TalentMatching
```

The Node template installs nvm and latest LTS Node inside that one project box.
Node and npm are not installed on the host.

## Create a .NET Environment

```bash
ws-new dotnet HackJack --with-devcontainer
ws-enter HackJack
```

The .NET template installs prerequisites and leaves SDK selection to the project.
Pin SDKs with `global.json` and install the matching SDK inside the project box.

## Add a New Template

1. Add `templates/project-envs/<name>.sh`.
2. Make it idempotent.
3. Install tools inside the Distrobox only.
4. Add an optional devcontainer template under `templates/devcontainer/<name>/`.
5. Document the new template in `templates/project-envs/README.md`.

Then run:

```bash
ws-new <name> MyProject
```

## Remove an Environment Safely

```bash
ws-remove Terrakit
```

Removal asks before deleting the Distrobox. It preserves
`~/Projects/Terrakit` by default and asks separately before deleting
`~/Boxes/projects/Terrakit`.

## Why Not Install Language Tooling on the Host?

Host-level language stacks become shared mutable state. They are easy to forget,
hard to reproduce, and often conflict across projects.

Project boxes make tooling explicit. If a project needs Rust nightly, Node LTS,
a specific .NET SDK, or a local database, that choice belongs to the project
environment rather than the machine.
