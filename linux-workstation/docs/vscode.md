# VS Code Without Host Install

VS Code is not installed on the host. It lives in Distroboxes.

## General Editing

Use `dev-base` for SDK-free editing, Git, notes, and odd jobs:

```bash
distrobox-enter --name dev-base -- bash -s < boxes/dev-base.sh
ws-code --base
```

`dev-base` contains VS Code, Git, Git LFS, SSH, ripgrep, fd, jq, shellcheck, and
basic desktop integration tools. It should not contain Rust, Node, .NET SDKs,
JDKs, databases, or project-specific CLIs.

## Project Editing

Project boxes install the same editor/Git baseline first, then add language
tooling:

```bash
ws-new rust Terrakit
ws-code Terrakit
```

This launches VS Code from `project-terrakit`, so integrated terminals and
editor tooling see that project box's environment.

## Lighter Project Boxes

Skip VS Code in a project box when you only need a shell:

```bash
ws-new python DataCheck --no-ide
```

You can still enter the environment with:

```bash
ws-enter DataCheck
```

## Why Not Host VS Code?

Installing VS Code on the host turns the editor into another place where
extensions, terminals, SDK assumptions, and project tools can drift. Keeping it
inside Distrobox preserves the host as a management OS.
