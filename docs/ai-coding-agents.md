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

AI tool configuration is project-local. It lives inside that project's custom
Distrobox home:

```text
~/Boxes/projects/<project>/.claude
~/Boxes/projects/<project>/.claude.json
~/Boxes/projects/<project>/.codex
```

That means each project may need its own Claude/Codex login or settings. This
is intentional: AI tools should see the same toolchain as the project, but their
config should not silently bleed into every other project.

If an older project used the previous shared `/work/ai-state` symlinks,
re-running `ws-ai-add <project> --claude`, `--codex`, or `--all` localizes those
symlinks back into the project home where possible.

Do not commit keys, tokens, `.env` files, or local agent settings.
