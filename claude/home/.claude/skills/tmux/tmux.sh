#!/usr/bin/env bash
# tmux.sh — helpers pra inspecionar e dirigir panes do tmux em um comando só.
#
#   tmux.sh ls                        → todas as windows
#   tmux.sh panes rd:1                → panes da window (com cmd e path)
#   tmux.sh cat rd:1.2 [linhas]       → últimas N linhas do pane (default 60)
#   tmux.sh hist rd:1.2 [padrão]      → comandos já rodados no pane (prompt ❯/$/#)
#   tmux.sh last rd:1.2 [padrão]      → último comando rodado no pane
#   tmux.sh run rd:1.2 'cmd'          → manda o comando + Enter e mostra o resultado
#   tmux.sh rerun rd:1.2 [padrão]     → repete o último comando (opcionalmente o último que casa)
#   tmux.sh keys rd:1.2 C-c           → manda teclas cruas (C-c, Escape, q, ...)
#
# Alvo é sempre sessão:window.pane (ex.: rd:1.2). `panes` aceita sessão:window.

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

CMD="${1:-ls}"; shift || true

prompt_re='^[[:space:]]*[❯$#][[:space:]]+'

case "$CMD" in
  ls)
    tmux list-windows -a -F '#{session_name}:#{window_index}  #{window_name}#{?window_active, (ativa),}  [#{window_panes} panes]'
    ;;
  panes)
    tmux list-panes -t "${1:?alvo}" -F '#{session_name}:#{window_index}.#{pane_index}  #{pane_current_command}#{?pane_active, (ativo),}  #{pane_current_path}'
    ;;
  cat)
    N="${2:-60}"
    tmux capture-pane -p -t "${1:?alvo}" -S "-$((N * 3))" | grep -v '^[[:space:]]*$' | tail -"$N"
    ;;
  hist)
    tmux capture-pane -p -t "${1:?alvo}" -S -5000 \
      | grep -E "$prompt_re" | sed -E "s/$prompt_re//" \
      | { [[ -n "${2:-}" ]] && grep -- "$2" || cat; } | tail -20
    ;;
  last)
    tmux capture-pane -p -t "${1:?alvo}" -S -5000 \
      | grep -E "$prompt_re" | sed -E "s/$prompt_re//" \
      | { [[ -n "${2:-}" ]] && grep -- "$2" || cat; } | tail -1
    ;;
  run)
    T="${1:?alvo}"; C="${2:?comando}"; W="${3:-4}"
    tmux send-keys -t "$T" "$C" Enter
    sleep "$W"
    tmux capture-pane -p -t "$T" -S -40 | grep -v '^[[:space:]]*$' | tail -20
    ;;
  rerun)
    T="${1:?alvo}"; PAT="${2:-}"
    LAST="$("$0" last "$T" "$PAT")"
    [[ -z "$LAST" ]] && { echo "nenhum comando encontrado no scrollback de $T" >&2; exit 1; }
    echo "→ $LAST" >&2
    "$0" run "$T" "$LAST"
    ;;
  keys)
    T="${1:?alvo}"; shift
    tmux send-keys -t "$T" "$@"
    sleep 1
    tmux capture-pane -p -t "$T" -S -20 | grep -v '^[[:space:]]*$' | tail -10
    ;;
  *) sed -n '2,20p' "$0" >&2; exit 1 ;;
esac
