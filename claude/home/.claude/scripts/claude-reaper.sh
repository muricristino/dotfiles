#!/usr/bin/env bash
# claude-reaper.sh — derruba sessões do Claude Code em janelas do tmux que
# você não visita há mais de 12h (via @visited, setado pelos hooks do
# .tmux.conf). Roda a cada 10 min pelo launchd (com.murilo.claude-reaper).
#
# Não mata claude ocupado (spinner/esc to interrupt) nem janelas sem
# @visited (sem dado = sem veredito). Sessões mortas voltam com --resume.
set -uo pipefail

MAX_IDLE=$((12 * 3600))
LOG=~/.claude/scripts/claude-reaper.log

now=$(date +%s)
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$LOG"; }

tmux list-panes -a -F '#{pane_pid}|#{pane_id}|#{session_name}:#{window_index}|#{window_name}|#{@visited}' 2>/dev/null |
  while IFS='|' read -r ppid pane loc wname visited; do
    [[ -n "$visited" ]] || continue
    idle=$((now - visited))
    ((idle > MAX_IDLE)) || continue

    for child in $(pgrep -P "$ppid" 2>/dev/null); do
      cmd=$(ps -o comm= -p "$child" 2>/dev/null)
      [[ "$cmd" == *claude* ]] || continue

      # ocupado? (spinner "… (Ns" ou "esc to interrupt" nas últimas linhas)
      tail=$(tmux capture-pane -p -t "$pane" 2>/dev/null | tail -15)
      if grep -qE 'esc to interrupt|… \(' <<<"$tail"; then
        log "skip $loc ($wname) pid $child: busy despite $((idle / 3600))h idle"
        continue
      fi

      rss=$(ps -o rss= -p "$child" 2>/dev/null | tr -d ' ')
      if kill "$child" 2>/dev/null; then
        log "killed $loc ($wname) pid $child: idle $((idle / 3600))h, rss $((${rss:-0} / 1024)) MB"
      fi
    done
  done

# mantém o log nas últimas 500 linhas
if [[ -f "$LOG" ]] && (($(wc -l <"$LOG") > 1000)); then
  tail -500 "$LOG" >"$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi
