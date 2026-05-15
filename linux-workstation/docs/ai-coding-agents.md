# AI Coding Agents

Claude Code and Codex CLI live in one shared `ai-code` Distrobox.

They are not host tools. They can read files, edit code, run commands, and hold
credentials, so they live outside the host while avoiding per-project auth setup.

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
the selected tool.

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
that in mind when authorizing commands.

For genuinely untrusted code, use a VM. Distrobox is not a hard security
boundary.
