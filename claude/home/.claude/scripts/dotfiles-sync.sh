#!/bin/sh
# SessionStart hook: pulls dotfiles in the background without blocking the session.
# New skills/settings from another machine land on the next `claude`.
DOTFILES="${DOTFILES:-$HOME/code/dotfiles}"
[ -d "$DOTFILES/.git" ] || exit 0
( git -C "$DOTFILES" pull --ff-only --quiet >/dev/null 2>&1 & )
exit 0
