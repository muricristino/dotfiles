#!/usr/bin/env bash
# tmux.sh — helpers to inspect and drive tmux panes in a single command.
#
#   tmux.sh ls                        → all windows
#   tmux.sh panes rd:1                → the window's panes (with cmd and path)
#   tmux.sh cat rd:1.2 [lines]        → last N lines of the pane (default 60)
#   tmux.sh hist rd:1.2 [pattern]     → commands already run in the pane (prompt ❯/$/#)
#   tmux.sh last rd:1.2 [pattern]     → last command run in the pane
#   tmux.sh run rd:1.2 'cmd'          → send the command + Enter and show the result
#   tmux.sh rerun rd:1.2 [pattern]    → repeat the last command (optionally the last one matching)
#   tmux.sh keys rd:1.2 C-c           → send raw keys (C-c, Escape, q, ...)
#
# The target is always session:window.pane (e.g. rd:1.2). `panes` accepts session:window.

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

CMD="${1:-ls}"; shift || true

prompt_re='^[[:space:]]*[❯$#][[:space:]]+'

case "$CMD" in
  ls)
    tmux list-windows -a -F '#{session_name}:#{window_index}  #{window_name}#{?window_active, (active),}  [#{window_panes} panes]'
    ;;
  panes)
    tmux list-panes -t "${1:?target}" -F '#{session_name}:#{window_index}.#{pane_index}  #{pane_current_command}#{?pane_active, (active),}  #{pane_current_path}'
    ;;
  cat)
    N="${2:-60}"
    tmux capture-pane -p -t "${1:?target}" -S "-$((N * 3))" | grep -v '^[[:space:]]*$' | tail -"$N"
    ;;
  hist)
    tmux capture-pane -p -t "${1:?target}" -S -5000 \
      | grep -E "$prompt_re" | sed -E "s/$prompt_re//" \
      | { [[ -n "${2:-}" ]] && grep -- "$2" || cat; } | tail -20
    ;;
  last)
    tmux capture-pane -p -t "${1:?target}" -S -5000 \
      | grep -E "$prompt_re" | sed -E "s/$prompt_re//" \
      | { [[ -n "${2:-}" ]] && grep -- "$2" || cat; } | tail -1
    ;;
  run)
    T="${1:?target}"; C="${2:?command}"; W="${3:-4}"
    tmux send-keys -t "$T" "$C" Enter
    sleep "$W"
    tmux capture-pane -p -t "$T" -S -40 | grep -v '^[[:space:]]*$' | tail -20
    ;;
  rerun)
    T="${1:?target}"; PAT="${2:-}"
    LAST="$("$0" last "$T" "$PAT")"
    [[ -z "$LAST" ]] && { echo "no command found in the scrollback of $T" >&2; exit 1; }
    echo "→ $LAST" >&2
    "$0" run "$T" "$LAST"
    ;;
  keys)
    T="${1:?target}"; shift
    tmux send-keys -t "$T" "$@"
    sleep 1
    tmux capture-pane -p -t "$T" -S -20 | grep -v '^[[:space:]]*$' | tail -10
    ;;
  *) sed -n '2,20p' "$0" >&2; exit 1 ;;
esac
