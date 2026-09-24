#!/bin/bash
# Generates window title: icon + folder name
# Usage: window-name.sh "$pane_current_command" "$pane_current_path"

cmd=$(basename "${1:-zsh}")
dir=$(basename "${2:-$HOME}")
[ "$dir" = "$(basename $HOME)" ] && dir="~"

case "$cmd" in
  nvim|vim)                icon=" " ;;
  lazygit)                 icon=" " ;;
  git)                     icon=" " ;;
  ruby|rails|irb|pry|rspec) icon=" " ;;
  node|bun|npm|npx|ts-node) icon=" " ;;
  python*|ipython)         icon=" " ;;
  elixir|mix|iex)          icon=" " ;;
  docker*)                 icon=" " ;;
  ssh|mosh)                icon=" " ;;
  htop|btop|top)           icon=" " ;;
  opencode|aider)          icon="󰚩 " ;;
  gh)                      icon=" " ;;
  make|rake)               icon=" " ;;
  psql|mysql|sqlite*)      icon=" " ;;
  zsh|bash|sh|fish)        icon=" " ;;
  *)                       icon=" " ;;
esac

echo "${icon}${dir}"
