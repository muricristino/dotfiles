#!/bin/bash
# Maps session name to nerd font icon via explicit UTF-8 hex bytes
# U+F0E7=bolt  U+F121=code  U+F201=chart  U+F544=robot  U+E235=python  U+F233=server  U+F07B=folder
session="$1"

# Machine-local overrides: ~/.config/tmux/session-icon.local (not versioned)
local_icons="$(dirname "$0")/session-icon.local"
if [ -f "$local_icons" ]; then
  icon=$(. "$local_icons")
  [ -n "$icon" ] && { printf '%s' "$icon"; exit 0; }
fi

case "$session" in
  code*)        printf '\xef\x84\xa1' ;;  # U+F121 fa-code
  *agent*)      printf '\xef\x95\x84' ;;  # U+F544 robot
  *python*)     printf '\xee\x88\xb5' ;;  # U+E235 python
  *api*)        printf '\xef\x88\xb3' ;;  # U+F233 server
  *)            printf '\xef\x81\xbb' ;;  # U+F07B folder
esac
