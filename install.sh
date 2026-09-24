#!/usr/bin/env bash

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --claude: também instala a config do Claude Code (settings base)
# --personal: config do Claude Code do dono do repo (hooks do codo + sync automático)
CLAUDE=""
for arg in "$@"; do
  case "$arg" in
    --claude)   CLAUDE=base ;;
    --personal) CLAUDE=personal ;;
    *) echo "uso: $0 [--claude | --personal]"; exit 2 ;;
  esac
done

echo "Dotfiles: $DOTFILES"

# Dependencies
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! command -v brew &>/dev/null; then
    echo "Instale o Homebrew primeiro: https://brew.sh"
    exit 1
  fi
  brew bundle --file="$DOTFILES/Brewfile"
elif ! command -v stow &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    sudo apt-get install -y stow
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y stow
  else
    echo "Instale stow manualmente: https://www.gnu.org/software/stow/"
    exit 1
  fi
fi

# Oh My Zsh + custom plugins
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Instalando Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-users/zsh-syntax-highlighting zsh-users/zsh-autosuggestions; do
  dest="$ZSH_CUSTOM/plugins/${plugin#*/}"
  [ -d "$dest" ] || git clone --depth 1 "https://github.com/$plugin" "$dest"
done

# tmux plugin manager
[ -d "$HOME/.tmux/plugins/tpm" ] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# Packages to stow (skip ghostty and nvim on Linux if not relevant)
PACKAGES=(zsh git tmux)
[ -n "$CLAUDE" ] && PACKAGES+=(claude)

if [[ "$OSTYPE" == "darwin"* ]]; then
  PACKAGES+=(ghostty nvim)
fi

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
    echo "Criado $dest — preencha com seus dados."
  fi
done

echo "Feito! Reinicie o terminal e rode prefix + I no tmux para instalar os plugins."
