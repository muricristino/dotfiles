#!/bin/sh
# Portable clipboard: `clip.sh copy` reads stdin, `clip.sh paste` writes to stdout.
# macOS (pbcopy), Wayland (wl-copy) or X11 (xclip).
case "$1" in
  copy)
    if   command -v pbcopy  >/dev/null; then pbcopy
    elif command -v wl-copy >/dev/null; then wl-copy
    elif command -v xclip   >/dev/null; then xclip -selection clipboard
    fi ;;
  paste)
    if   command -v pbpaste  >/dev/null; then pbpaste
    elif command -v wl-paste >/dev/null; then wl-paste --no-newline
    elif command -v xclip    >/dev/null; then xclip -selection clipboard -o
    fi ;;
  *) echo "usage: clip.sh copy|paste" >&2; exit 2 ;;
esac
