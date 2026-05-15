# AI Coding Agents

Claude Code and Codex CLI live in separate tool boxes:

- `claude-code`
- `codex`

They are not installed on the host and not duplicated into every project box.

Setup:

```bash
ws-ai-setup
```

Run against a project:

```bash
ws-claude ExampleProject
ws-codex ExampleProject
```

Behavior:

- `ws-claude` enters the project Distrobox, then exposes a `claude` launcher.
- `ws-codex` enters the project Distrobox, then exposes a `codex` launcher.
- The real CLI and auth state still live in `claude-code` or `codex`.
- Shell commands spawned by the AI tool are routed back through the project
  Distrobox, so the project toolchain is the normal command context.

Useful check:

```bash
ws-enter ExampleProject
cargo --version
```

Then:

```bash
ws-claude ExampleProject
```

Agent state lives under:

```text
~/Boxes/claude-code
~/Boxes/codex
```

Do not commit keys, tokens, `.env` files, or local agent settings.
