#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --claude: also installs the Claude Code config (base settings)
# --personal: the repo owner's Claude Code config (codo hooks + auto sync)
CLAUDE=""
for arg in "$@"; do
  case "$arg" in
    --claude)   CLAUDE=base ;;
    --personal) CLAUDE=personal ;;
    *) echo "usage: $0 [--claude | --personal]"; exit 2 ;;
  esac
done

echo "Dotfiles: $DOTFILES"

# Dependencies: Homebrew on macOS and Linux; apt/dnf as a fallback on Linux
if [[ "$OSTYPE" == "linux"* ]] && ! command -v brew &>/dev/null; then
  for brew in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    [ -x "$brew" ] && eval "$("$brew" shellenv)" && break
  done
fi

if command -v brew &>/dev/null; then
  brew bundle --file="$DOTFILES/Brewfile"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Install Homebrew first: https://brew.sh"
  exit 1
else
  # No Homebrew: distro packages, one at a time (names and availability vary).
  # The distro's neovim may be too old for LazyVim; Homebrew avoids that.
  pkgs=(stow git zsh tmux neovim fzf jq ripgrep curl eza git-delta git-lfs gh)
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    install_pkg() { sudo apt-get install -y -qq "$1" >/dev/null; }
    pkgs+=(fd-find)
  elif command -v dnf &>/dev/null; then
    install_pkg() { sudo dnf install -y -q "$1" >/dev/null; }
    pkgs+=(fd-find)
  else
    echo "Install manually: ${pkgs[*]}"
    exit 1
  fi
  for pkg in "${pkgs[@]}"; do
    install_pkg "$pkg" || echo "  warning: $pkg not installed"
  done
  command -v stow &>/dev/null || { echo "stow is required"; exit 1; }
fi

# Oh My Zsh + custom plugins
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-users/zsh-syntax-highlighting zsh-users/zsh-autosuggestions; do
  dest="$ZSH_CUSTOM/plugins/${plugin#*/}"
  [ -d "$dest" ] || git clone --depth 1 "https://github.com/$plugin" "$dest"
done

# tmux plugin manager
[ -d "$HOME/.tmux/plugins/tpm" ] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# Packages to stow
PACKAGES=(zsh git tmux nvim ghostty)
[ -n "$CLAUDE" ] && PACKAGES+=(claude)

# Shared parents must be real dirs, or stow folds them into the first package
mkdir -p "$HOME/.config" "$HOME/.claude"

for pkg in "${PACKAGES[@]}"; do
  echo "Stowing $pkg..."
  # Existing real files would make stow abort: move them aside first
  (cd "$DOTFILES/$pkg/home" && find . \( -type f -o -type l \) ! -name '.DS_Store') | while read -r f; do
    target="$HOME/${f#./}"
    # Already reached through a stowed directory link: it's the repo file itself
    [ "$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)" = "$(cd "$DOTFILES/$pkg/home/$(dirname "${f#./}")" && pwd -P)" ] && continue
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "  backup: $target -> $target.bak"
      mv "$target" "$target.bak"
    fi
  done
  stow --dir="$DOTFILES/$pkg" --target="$HOME" --restow home
done

# Claude Code settings: link, not stow, so edits made by Claude Code land in the repo
if [ -n "$CLAUDE" ]; then
  settings="$HOME/.claude/settings.json"
  [ -e "$settings" ] && [ ! -L "$settings" ] && mv "$settings" "$settings.bak" && echo "  backup: $settings -> $settings.bak"
  ln -sfn "$DOTFILES/claude/settings/$CLAUDE.json" "$settings"
  echo "Claude Code settings: $CLAUDE"
fi

# Machine-specific files from examples (not tracked)
for pair in "zsh/home/.zshrc.local.example:.zshrc.local" "git/home/.gitconfig.local.example:.gitconfig.local"; do
  src="$DOTFILES/${pair%%:*}"; dest="$HOME/${pair#*:}"
  if [ ! -f "$dest" ]; then
    cp "$src" "$dest"
    echo "Created $dest — fill in your details."
  fi
done

if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
  echo "Your default shell is not zsh. To switch: chsh -s \"$(command -v zsh)\""
fi

echo "Done! Restart the terminal and press prefix + I in tmux to install the plugins."
