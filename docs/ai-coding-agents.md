# AI Coding Agents

Claude Code and Codex CLI live in one shared `ai-code` Distrobox.

They are not host tools. They can read files, edit code, run commands, and hold
credentials, so they live outside the host while avoiding per-project auth setup.
When launched for a project, `ws-claude` and `ws-codex` expose that project's
Distrobox tools into the `ai-code` session.

## Configure Or Update

```bash
ws-ai-setup
```

Bootstrap runs this automatically after creating the `ai-code` Distrobox. Run it
manually later to repair or update Claude Code and Codex CLI.

The box mounts:

```text
~/Projects -> /work/projects
~/Scratch  -> /work/scratch
```

## Run Against a Project

From the host:

```bash
ws-claude TerraKit
ws-codex TerraKit
ws-ai-shell TerraKit
```

Those commands enter `ai-code`, change to `/work/projects/TerraKit`, and launch
the selected tool. A temporary command bridge is added so shell commands run in
the matching project Distrobox, for example `project-terrakit`.

The launcher exports `SHELL` to a generated project-command shell. AI tools that
run commands through `$SHELL -c ...` execute those commands in the project box,
with the working directory mapped from `/work/projects/TerraKit` to
`/work/terrakit`. Common direct tool executions such as `cargo`, `node`, `npm`,
`dotnet`, `python3`, `java`, `cmake`, and `composer` are also shimmed into the
project box.

For repo-local scripts that bypass `PATH`, run them through:

```bash
ws-project-exec ./gradlew test
ws-project-exec ./scripts/test.sh
```

To open an interactive shell in the project Distrobox from inside `ai-code`:

```bash
ws-project-shell
```

If the agent needs a normal Ubuntu package for that project, it can install it
into the project Distrobox:

```bash
ws-project-apt-install just
ws-project-apt-install libsqlite3-dev pkg-config
```

Disable the bridge for one run when you want the plain `ai-code` environment:

```bash
ws-claude --no-tool-bridge TerraKit
```

Override the bridged command list for unusual projects:

```bash
WS_AI_BRIDGE_TOOLS="cargo rustc just taplo" ws-claude TerraKit
```

## What Gets Installed

`boxes/ai-code.sh` installs:

- Node LTS through nvm.
- `@anthropic-ai/claude-code`.
- `@openai/codex`.
- Git, Git LFS, SSH, ripgrep, fd, jq, tree, shellcheck, and basic CLI helpers.

These are installed inside the `ai-code` Distrobox, not on the host.

## Credentials

Claude Code stores its user state under the box home:

```text
~/Boxes/ai-code/.claude
```

Codex can use an environment variable:

```bash
export OPENAI_API_KEY="<your-openai-api-key>"
```

Prefer per-box shell config or a local secret manager. Do not commit keys,
tokens, `.env` files, or local agent settings.

## Why One Shared Box?

A single `ai-code` box avoids re-authenticating and reinstalling AI tools for
every project. It still keeps those tools off the host and gives them a custom
home directory that can be backed up, inspected, or removed separately.

The tradeoff is scope: `ai-code` can access projects under `~/Projects`. Keep
that in mind when authorizing commands. The tool bridge also lets the agent run
commands and install apt packages inside the selected project Distrobox.

For genuinely untrusted code, use a VM. Distrobox is not a hard security
boundary.
