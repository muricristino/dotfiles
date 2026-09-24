# dotfiles

Personal config for macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

```
dotfiles/
├── zsh/        → ~/.zshrc, ~/.zshrc.local.example
├── git/        → ~/.gitconfig, ~/.gitconfig.local.example
├── tmux/       → ~/.tmux.conf, ~/.config/tmux/
├── ghostty/    → ~/.config/ghostty/ (config, theme, icon)
├── nvim/       → ~/.config/nvim/ (LazyVim)
├── claude/     → ~/.claude/ (settings.json, CLAUDE.md, scripts/, skills/)
└── Brewfile    → dependencies
```

## Installation

Requires [Homebrew](https://brew.sh).

```bash
git clone <repo> ~/code/dotfiles
cd ~/code/dotfiles
./install.sh
```

`install.sh` installs the Brewfile, Oh My Zsh with its plugins and TPM, then stows every package. Existing files that would conflict are moved to `<file>.bak`.

## Machine-specific config

These files are not tracked. `install.sh` creates them from the examples:

| File | Holds |
|---|---|
| `~/.zshrc.local` | secrets and machine-only shell config |
| `~/.gitconfig.local` | git `user.name` and `user.email` |
| `~/.config/tmux/session-icon.local` | extra tmux session icons |

## Claude Code

`~/.claude/skills` is a link into this repo, so a skill created on this machine lands here. Commit and push it, and every other machine picks it up: a `SessionStart` hook runs `git pull` on the dotfiles in the background.

Skills that stay local are listed in `.gitignore`: work skills, third-party skills installed as links, and browser profiles.

## Adding a new config

```bash
mkdir -p <name>/home/.<path>
stow --dir=<name> --target=$HOME --restow home
```
