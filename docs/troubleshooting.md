# Troubleshooting

## Flathub Not Added

Run:

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remotes
```

Then rerun:

```bash
./scripts/install-flatpaks.sh
```

## Flatpak Apps Do Not Appear

Log out and back in, or reboot. Desktop launchers sometimes appear only after
the session refreshes.

## Podman Rootless Issues

Check:

```bash
podman info
```

If rootless storage or user namespace errors appear, reboot after installing
Podman. On unusual systems, verify `/etc/subuid` and `/etc/subgid` contain an
entry for your user.

## Distrobox Creation Failures

Check:

```bash
podman info
distrobox-list
```

Then try creating a small test box:

```bash
distrobox-create --name test-box --image ubuntu:24.04 --yes
```

If image pulls fail, check network access and registry availability.

## Project Environment Creation Failures

Run:

```bash
ws-list
distrobox-list
```

If the Distrobox exists but template setup failed, rerun:

```bash
ws-new <template> <project-name>
```

Templates are designed to be idempotent.

## PATH Does Not Find ws-new or ws-enter

Run the shell integration script:

```bash
./scripts/install-shell-integration.sh
source ~/.bashrc
```

Confirm:

```bash
command -v ws-new
command -v ws-enter
```

## VS Code Does Not Launch From ws-code

Confirm the selected box exists:

```bash
distrobox-list
```

Confirm VS Code is installed inside that box:

```bash
distrobox-enter --name project-terrakit -- command -v code
```

For the base editor box, configure it first:

```bash
distrobox-enter --name dev-base -- bash -s < boxes/dev-base.sh
ws-code --base
```

If GUI windows do not appear, test another simple GUI app from inside the box and
check Wayland/X11 integration for your Distrobox version and desktop session.

## Claude Code or Codex Is Missing

Repair or update the shared AI tools box:

```bash
ws-ai-setup
```

Then check inside the box:

```bash
distrobox-enter --name ai-code
command -v claude
command -v codex
```

If those commands are missing but Node was installed with nvm, rerun:

```bash
ws-ai-setup
```

If nvm reports that `NVM_DIR` points at a directory that does not exist, update
the repo and rerun `ws-ai-setup`. The setup script creates `~/.nvm` inside the
custom `ai-code` home before running the installer.

Run agents against a project from the host:

```bash
ws-claude TerraKit
ws-codex TerraKit
```

Bootstrap runs `ws-ai-setup` automatically, but the command is safe to rerun.
Claude Code and Codex CLI require network access for install and authentication.
Do not install them on the host.

## AI Agent Cannot Find Project SDK Tools

`ws-claude <project>` and `ws-codex <project>` expose common SDK commands from
the matching project Distrobox into `ai-code`.

Confirm the project Distrobox exists:

```bash
distrobox-list
```

Then open a bridged shell:

```bash
ws-ai-shell TerraKit
pwd
command -v cargo
cargo --version
```

`ws-ai-shell <project>` opens an interactive shell directly in the project
Distrobox. `pwd` should be the project mount inside that box, such as
`/work/terrakit`, and `cargo --version` should run directly there.

For Claude/Codex launches, the wrapper runs the AI tool from `ai-code` but
exports `SHELL` to a generated project-command shell. Shell commands spawned via
`$SHELL -c ...` run inside the project Distrobox. Common direct tool executions
such as `cargo`, `node`, `dotnet`, and `python3` are still shimmed as a fallback.
The bridge deliberately does not shadow `bash` or `sh`, because that breaks
scripts using `#!/usr/bin/env bash`.

If `ws-claude <project>` reports that the AI tool bridge could not enter the
project box, first check whether Distrobox host integration is visible inside
`ai-code`:

```bash
distrobox-enter --name ai-code -- bash -lc 'command -v distrobox-host-exec && distrobox-host-exec --yes true'
```

Do not install the Ubuntu `distrobox` apt package inside the `ai-code`
Distrobox. Distrobox may already inject host-managed files such as
`/usr/bin/distrobox-export`, and dpkg can fail with `Invalid cross-device link`
when trying to replace them.

If that happened, repair the package state inside `ai-code`:

```bash
distrobox-enter --name ai-code -- bash -lc 'sudo dpkg --remove --force-remove-reinstreq distrobox 2>/dev/null || true; sudo apt-get -f install; sudo dpkg --configure -a'
```

Then update this repository and rerun:

```bash
ws-ai-setup
```

Then retry:

```bash
ws-claude TerraKit
```

If a bridged command hangs, rerun it with bridge debugging enabled:

```bash
WS_AI_BRIDGE_DEBUG=1 cargo --version
WS_AI_BRIDGE_DEBUG=1 ws-project-exec cargo --version
```

Tool commands use `distrobox-enter --no-tty` through `distrobox-host-exec`,
because Distrobox recommends disabling TTY allocation for script-style command
execution.

If repo-local scripts bypass `PATH`, run them through the project box explicitly:

```bash
ws-project-exec ./gradlew test
ws-project-exec ./scripts/test.sh
```

If the agent needs an apt package for this project, install it inside the
project Distrobox:

```bash
ws-project-apt-install just
ws-project-apt-install libssl-dev pkg-config
```

The bridge depends on `distrobox-host-exec` being available inside `ai-code`.
If it is missing, update Distrobox and recreate or update the `ai-code` box.

## NVIDIA and GPU Caveats

GPU support depends on the host driver stack. Flatpak, Distrobox, Steam, and
VMs each have their own integration details. If GPU workloads fail, first
confirm the host driver works outside containers.

## Steam and Gaming Caveats

Steam Flatpak is a good default for host cleanliness and is included in
`config/flatpaks.txt`.

There is no default gaming Distrobox. Create one manually only when Flatpak
Steam is not enough for a specific launcher, mod manager, or experiment.

Gaming inside Distrobox can work, but compatibility varies. Anti-cheat, Proton,
controller support, and GPU integration may behave differently than Steam
Flatpak or a normal host install.

## When To Use a VM Instead

Use a VM for:

- Genuinely untrusted software.
- Windows-only tools.
- Kernel modules or low-level system changes.
- Malware-adjacent analysis.
- Experiments that might damage a user session.

Distrobox is for contamination control and workflow separation, not strong
malware isolation.
