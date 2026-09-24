#!/usr/bin/env bash
# print.sh — print da tela, opcionalmente de uma window específica do tmux
#
#   print.sh                  → print da tela como está
#   print.sh --list           → lista as windows do tmux
#   print.sh belchior         → troca pra window com esse nome e printa
#   print.sh axolutions:6     → troca pra sessão:window e printa
#   print.sh --text belchior  → dump em texto do conteúdo da window (sem imagem)
#
# Depois de printar, volta pra window/sessão que estava antes.

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

OUTDIR="${CLAUDE_SCRATCHPAD:-/tmp}"
TERM_APP="${PRINT_TERM_APP:-Ghostty}"
MODE=image
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list|-l)
      tmux list-windows -a -F '#{session_name}:#{window_index}  #{window_name}#{?window_active, (ativa),}  [#{window_panes} panes]'
      exit 0 ;;
    --text|-t) MODE=text; shift ;;
    *) TARGET="$1"; shift ;;
  esac
done

resolve() { # nome | sessão:idx | sessão:nome → sessão:idx
  local q="$1"
  if [[ "$q" == *:* ]] && tmux list-windows -a -F '#{session_name}:#{window_index}' | grep -qx "$q"; then
    echo "$q"; return
  fi
  # sessão:nome — desambigua um nome repetido em várias sessões
  if [[ "$q" == *:* ]]; then
    tmux list-windows -a -F '#{session_name}:#{window_index} #{session_name} #{window_name}' \
      | awk -v s="${q%%:*}" -v n="${q#*:}" '$2 == s && $3 == n {print $1; exit}'
    return
  fi
  tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}' \
    | awk -v n="$q" '$2 == n {print $1; exit}'
}

if [[ -n "$TARGET" ]]; then
  WIN="$(resolve "$TARGET")"
  if [[ -z "$WIN" ]]; then
    echo "window '$TARGET' não encontrada. Disponíveis:" >&2
    tmux list-windows -a -F '  #{session_name}:#{window_index}  #{window_name}' >&2
    exit 1
  fi
fi

if [[ "$MODE" == text ]]; then
  tmux capture-pane -p -t "${WIN:-}" -S -200
  exit 0
fi

# --- imagem ---
PREV_SESSION="" PREV_WINDOW=""
if [[ -n "${WIN:-}" ]]; then
  PREV_SESSION="$(tmux display-message -p '#{session_name}')"
  PREV_WINDOW="$(tmux display-message -p '#{session_name}:#{window_index}')"
  TARGET_SESSION="${WIN%%:*}"
  [[ "$TARGET_SESSION" != "$PREV_SESSION" ]] && tmux switch-client -t "$TARGET_SESSION" 2>/dev/null || true
  tmux select-window -t "$WIN"
  osascript -e "tell application \"$TERM_APP\" to activate" 2>/dev/null || true
  sleep 0.6
fi

OUT="$OUTDIR/print-$(date +%H%M%S).png"
screencapture -x "$OUT"
sips -Z 1400 "$OUT" --out "${OUT%.png}-small.png" >/dev/null

if [[ -n "$PREV_WINDOW" ]]; then
  tmux select-window -t "$PREV_WINDOW" 2>/dev/null || true
  [[ "${TARGET_SESSION:-}" != "$PREV_SESSION" ]] && tmux switch-client -t "$PREV_SESSION" 2>/dev/null || true
fi

echo "${OUT%.png}-small.png"
