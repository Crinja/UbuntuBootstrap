# Dotfiles

This repository is not a full dotfiles framework. It keeps host changes
deliberate and visible.

## Bash helpers

To add `ws-new`, `ws-enter`, `ws-list`, `ws-remove`, and `ws-help` to your shell:

```bash
echo 'source "/path/to/linux-workstation/dotfiles/bashrc.append"' >> ~/.bashrc
source ~/.bashrc
```

Use the real path where you cloned this repository.

## Git config

`gitconfig.example` is only a starting point. Review it before copying any
settings into `~/.gitconfig`.
