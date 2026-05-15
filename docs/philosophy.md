# Philosophy

The workstation is split into layers.

## Ubuntu Host as Management Plane

The host should run the machine, manage hardware, provide the desktop session,
run backups/snapshots, and launch isolated workspaces. It should not accumulate
every language toolchain and project dependency you have ever needed.

The rule is simple:

> If it is not needed to run the machine itself, it does not belong on the host.

## Flatpak for Desktop Apps

Desktop applications are installed through Flatpak wherever reasonable. This
keeps GUI app dependency trees out of the host apt layer and makes permission
management visible through Flatseal.

## Project-Scoped Distroboxes for Development

Development environments are project-scoped:

- `project-terrakit`
- `project-hackjack`
- `project-csit314-talentmatching`

Each project gets its own Distrobox, its own custom home directory, its own
source folder, and its own tooling. This makes projects easier to reproduce,
retire, or rebuild without contaminating the host or other projects.

## Base Distroboxes for Broad Tasks

Base boxes exist for broad categories:

- `ai-code`
- `dev-base`
- `experimental`

They are intentionally not language stacks. `dev-base` contains VS Code, Git,
SSH, and workflow basics. `ai-code` contains Claude Code, Codex CLI, and only the
runtime needed for those tools. Neither should become a project SDK box.

Project templates reuse the same base development layer, then add language
tooling inside the project box where it belongs.

## Devcontainers for Repository Reproducibility

Devcontainers live with a repository and describe how that repo should be opened
by container-aware editors. They are useful when collaborators or CI workflows
expect a container definition.

The `ws-new --with-devcontainer` flag copies a starter template into the project
without changing host tooling.

## VMs for Stronger Boundaries

Distrobox is for host cleanliness and workflow separation. It shares enough of
your user session that it should not be treated as a hard security boundary.

Use a VM for high-risk, hostile, unknown, kernel-level, or incompatible software.
