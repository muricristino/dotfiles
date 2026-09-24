#!/bin/sh
# SessionStart hook: puxa o dotfiles em background, sem travar a sessão.
# Skills/settings novos de outra máquina chegam no próximo `claude`.
DOTFILES="${DOTFILES:-$HOME/code/dotfiles}"
[ -d "$DOTFILES/.git" ] || exit 0
( git -C "$DOTFILES" pull --ff-only --quiet >/dev/null 2>&1 & )
exit 0
