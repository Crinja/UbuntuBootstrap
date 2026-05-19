# VS Code

VS Code is installed as a Flatpak GUI app.

Project editor:

```bash
ws-new rust ExampleProject
ws-code ExampleProject
```

That launches the VS Code Flatpak with:

```text
Folder:  ~/Projects/ExampleProject
Profile: project-exampleproject
```

Extensions and editor settings installed while that profile is active stay
separate from other project profiles.

Project Distroboxes still own the toolchains:

```bash
ws-enter ExampleProject
```

For extensions that must run inside a container with the project toolchain, use
a devcontainer:

```bash
ws-new node WebApp --with-devcontainer --with-docker
```
