# Dotfiles

Not a dotfiles framework. This folder only holds small bootstrap snippets.

`bootstrap.sh` adds `dotfiles/bashrc.append` to `~/.bashrc` so `ws-*` commands
are available in new Bash terminals.

Manual repair:

```bash
./scripts/install-shell-integration.sh
source ~/.bashrc
```

`gitconfig.example` is a scratch example, not something the bootstrap installs.
