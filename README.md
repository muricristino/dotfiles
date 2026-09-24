# dotfiles

Personal config for macOS and Linux, managed with [GNU Stow](https://www.gnu.org/software/stow/).

[![install](https://github.com/muricristino/dotfiles/actions/workflows/install.yml/badge.svg)](https://github.com/muricristino/dotfiles/actions/workflows/install.yml)

## Structure

```
dotfiles/
├── zsh/        → ~/.zshrc, ~/.zshrc.local.example
├── git/        → ~/.gitconfig, ~/.gitconfig.local.example
├── tmux/       → ~/.tmux.conf, ~/.config/tmux/
├── ghostty/    → ~/.config/ghostty/ (config, theme, icon)
├── nvim/       → ~/.config/nvim/ (LazyVim)
├── claude/     → ~/.claude/ (CLAUDE.md, scripts/, skills/), optional
│   └── settings/   base.json or personal.json → ~/.claude/settings.json
└── Brewfile    → dependencies
```

## Installation

Uses [Homebrew](https://brew.sh) on macOS and Linux. On Linux without Homebrew, it falls back to `apt` or `dnf`, but the distro's neovim is usually too old for LazyVim.

```bash
git clone <repo> ~/code/dotfiles
cd ~/code/dotfiles
./install.sh              # zsh, git, tmux, nvim, ghostty
./install.sh --claude     # + Claude Code config with base settings
```

`install.sh` installs the dependencies, Oh My Zsh with its plugins and TPM, then stows every package. Existing files that would conflict are moved to `<file>.bak`. CI runs it on macOS, Ubuntu with Homebrew and Ubuntu with apt on every push.

## Machine-specific config

These files are not tracked. `install.sh` creates them from the examples:

| File | Holds |
|---|---|
| `~/.zshrc.local` | secrets and machine-only shell config |
| `~/.gitconfig.local` | git `user.name` and `user.email` |
| `~/.config/tmux/session-icon.local` | extra tmux session icons |

## Claude Code

The `claude` package is opt-in. `--claude` links `settings/base.json`, which has no hooks and no account-specific values. `--personal` links `settings/personal.json` instead: my own setup, with hooks for [codo](https://codo.axolutions.com.br) and the sync described below. It needs tools that aren't in this repo, so don't use it on your machine.

`~/.claude/settings.json` is a link to one of those files, so changes Claude Code writes to its settings land in the repo.

`~/.claude/skills` is a link into this repo, so a skill created on this machine lands here. Commit and push it, and my other machines pick it up: in the personal settings, a `SessionStart` hook runs `git pull` on the dotfiles in the background.

Skills that stay local are listed in `.gitignore`: work skills, third-party skills installed as links, and browser profiles.

## Adding a new config

```bash
mkdir -p <name>/home/.<path>
stow --dir=<name> --target=$HOME --restow home
```
