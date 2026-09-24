#!/usr/bin/env bash
# claude-reaper.sh — kills Claude Code sessions in tmux windows you
# haven't visited in over 12h (via @visited, set by the hooks in
# .tmux.conf). Runs every 10 min via launchd (com.murilo.claude-reaper).
#
# Never kills a busy claude (spinner/esc to interrupt) or windows without
# @visited (no data = no verdict). Killed sessions come back with --resume.
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

      # busy? (spinner "… (Ns" or "esc to interrupt" in the last lines)
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

# keep the log to the last 500 lines
if [[ -f "$LOG" ]] && (($(wc -l <"$LOG") > 1000)); then
  tail -500 "$LOG" >"$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi
