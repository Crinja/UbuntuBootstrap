# AI Coding Agents

Claude Code and Codex CLI are project-local opt-ins.

They are not installed on the host and not installed in every project box. When
enabled, the CLI binary lives inside that project Distrobox, so commands run in
the same environment as the project toolchain.

Create a project with AI tools:

```bash
ws-new rust AgentProject --with-claude
ws-new node AgentWeb --with-ai
```

Add AI tools later:

```bash
ws-ai-add ExampleProject --claude
ws-ai-add ExampleProject --codex
ws-ai-add ExampleProject --all
```

Run inside a project:

```bash
ws-enter ExampleProject
claude
codex
```

Useful check:

```bash
ws-enter ExampleProject
command -v claude
command -v codex
cargo --version
```

Shared state lives under:

```text
~/Boxes/ai-state/claude
~/Boxes/ai-state/codex
```

Project boxes mount that state at:

```text
/work/ai-state/claude
/work/ai-state/codex
```

Do not commit keys, tokens, `.env` files, or local agent settings.
