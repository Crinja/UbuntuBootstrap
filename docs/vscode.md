# VS Code

VS Code is not installed on the host.

Project editor:

```bash
ws-new rust ExampleProject
ws-code ExampleProject
```

That launches Code from the project Distrobox, so integrated terminals see the
project toolchain. New project boxes install VS Code by default.

Skip VS Code in a project box:

```bash
ws-new python DataCheck --no-ide
```

If I want a general editor box later, create it manually and use:

```bash
ws-code --box <box-name>
```
