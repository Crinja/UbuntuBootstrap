# Dotfiles

This repository is not a full dotfiles framework. It keeps host changes
deliberate and visible.

## Bash helpers

`bootstrap.sh` installs the Bash integration automatically by adding a managed
block to `~/.bashrc`.

Manual install or repair:

To add all `ws-*` helper commands to your shell:

```bash
./scripts/install-shell-integration.sh
source ~/.bashrc
```

Run the command from the repository root.

## Git config

`gitconfig.example` is only a starting point. Review it before copying any
settings into `~/.gitconfig`.
