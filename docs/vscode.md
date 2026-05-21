# VS Code

VS Code is installed as a Flatpak GUI app.

Project editor:

```bash
ws-new rust ExampleProject
ws-code ExampleProject
```

That launches the VS Code Flatpak with:

```text
Folder:     ~/Projects/ExampleProject
User data:  ~/Boxes/projects/ExampleProject/.vscode-flatpak/user-data
Extensions: ~/Boxes/projects/ExampleProject/.vscode-flatpak/extensions
```

Extensions and editor settings installed from that window stay local to that
project's Code state. Opening Code normally uses the default Flatpak Code state.

The integrated terminal defaults to a `Project Distrobox` profile that runs:

```text
flatpak-spawn --host /usr/bin/distrobox-enter --name project-exampleproject -- bash -lc 'cd /work/exampleproject && exec bash -i'
```

So a new VS Code terminal starts inside the project Distrobox with the project
toolchain available.

When a project is created or updated with `--with-devcontainer` or
`--with-podman`, `ws-code` creates project-local Podman bridge scripts and
installs the Dev Containers extension into that project's extension directory.
It also points the extension at the Podman bridge scripts:

```text
~/Boxes/projects/ExampleProject/.vscode-flatpak/bin/podman
~/Boxes/projects/ExampleProject/.vscode-flatpak/bin/podman-compose
```

The bridge is not created for normal projects. To enable it for an existing
project that already has `.devcontainer/`, rerun:

```bash
ws-new generic ExampleProject --with-podman
ws-code ExampleProject
```

Project Distroboxes still own the toolchains outside the editor too:

```bash
ws-enter ExampleProject
```

For extensions that must run inside a container with the project toolchain, use
a devcontainer:

```bash
ws-new node WebApp --with-devcontainer
```
