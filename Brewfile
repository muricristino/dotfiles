# Dependencies used by these dotfiles — `brew bundle` (install.sh runs it on macOS and Linux)

# core
brew "stow"
brew "git"
brew "git-delta"   # git pager
brew "git-lfs"
brew "gh"          # git credential helper, PR helpers
brew "jq"

# shell
brew "eza"         # ls/ll aliases
brew "fzf"
brew "asdf"
brew "tmux"

# neovim and plugin tools
brew "neovim"
brew "ripgrep"     # telescope live grep
brew "fd"          # telescope file finder
brew "lazygit"     # lazygit.nvim
brew "imagemagick" # image.nvim

# Linux: zsh doesn't come preinstalled on most distros
if OS.linux?
  brew "zsh"
end

# macOS only: casks don't exist on Linux, and Linux sed is already GNU sed
if OS.mac?
  brew "gnu-sed"   # nvim-spectre (gsed)
  cask "ghostty"
  cask "font-jetbrains-mono-nerd-font"
end
