#!/usr/bin/env bash
# prefix + f — fzf window search (all sessions), sorted by last real
# visit (@visited, set by the hooks in .tmux.conf).
# Icons: session via session-icon.sh, window via command icon (window-name.sh).
set -uo pipefail

# run-shell has no tty: reopen inside a tmux popup.
if [[ "${1:-}" != "--popup" ]]; then
  tmux display-popup -E -w 100 -h 60% "$0 --popup"
  exit 0
fi

export LC_ALL="${LC_ALL:-en_US.UTF-8}"

current=$(tmux display-message -p '#{window_id}')
ALL_PANES=$(tmux list-panes -a -F '#{window_id} #{pane_id} #{pane_current_command}')

# Vim mode in fzf: starts in insert; esc enters normal mode (j/k/g/G/d/u/q),
# i goes back to insert. Keys are defined in --bind and unbound at start.
VIM_KEYS='j,k,g,G,d,u,q'
PROMPT_INS="$(printf '\xef\x80\x82') ❯ "
PROMPT_NRM="$(printf '\xef\x80\x82') [N] ❯ "

# Icons via explicit UTF-8 bytes (same technique as session-icon.sh —
# literal nerd-font glyphs don't survive edits by tools).
cmd_icon() {
  case "$(basename "${1:-zsh}")" in
    nvim|vim)                 printf '\xee\x98\xab ' ;;  # U+E62B vim
    lazygit|git)              printf '\xee\x9c\x82 ' ;;  # U+E702 git
    ruby|rails|irb|pry|rspec) printf '\xee\x9c\xb9 ' ;;  # U+E739 ruby
    node|bun|npm|npx|ts-node) printf '\xee\x9c\x98 ' ;;  # U+E718 nodejs
    python*|ipython)          printf '\xee\x88\xb5 ' ;;  # U+E235 python
    elixir|mix|iex)           printf '\xee\x98\xad ' ;;  # U+E62D elixir
    docker*)                  printf '\xef\x8c\x88 ' ;;  # U+F308 docker
    ssh|mosh)                 printf '\xef\x92\x89 ' ;;  # U+F489 terminal (oct)
    htop|btop|top)            printf '\xef\x83\xa4 ' ;;  # U+F0E4 tachometer
    opencode|aider|claude|[0-9]*.[0-9]*) printf '\xef\x95\x84 ' ;;  # U+F544 robot (claude shows up as "2.1.233")
    gh)                       printf '\xef\x82\x9b ' ;;  # U+F09B github
    make|rake)                printf '\xef\x82\xad ' ;;  # U+F0AD wrench
    psql|mysql|sqlite*)       printf '\xef\x87\x80 ' ;;  # U+F1C0 database
    zsh|bash|sh|fish)         printf '\xef\x84\xa0 ' ;;  # U+F120 terminal
    *)                        printf '\xef\x81\xbb ' ;;  # U+F07B folder
  esac
}

# Claude Code status in the window (checks every pane, not just the active one):
#   waiting = asking for approval  ·  busy = working  ·  idle = ready
claude_status() {
  local win=$1 best="" pid pcmd tail
  grep "^$win " <<<"$ALL_PANES" |
    { while read -r _ pid pcmd; do
        case "$pcmd" in claude|[0-9]*.[0-9]*) ;; *) continue ;; esac
        tail=$(tmux capture-pane -p -t "$pid" 2>/dev/null | tail -15)
        if grep -qE 'Do you want|Would you like|No, and tell' <<<"$tail"; then
          best="waiting"; break
        elif grep -qE 'esc to interrupt|… \(' <<<"$tail"; then
          best="busy"
        elif [[ -z "$best" ]]; then
          best="idle"
        fi
      done
      echo "$best"; }
}

# Colored status column, fixed width (10 visible chars)
status_col() {
  local st txt color
  st=$(claude_status "$1")
  case "$st" in
    waiting) color=$'\033[31m'; txt='● approve?' ;;
    busy)    color=$'\033[33m'; txt='● busy' ;;
    idle)    color=$'\033[32m'; txt='● ready' ;;
    *)       printf '%10s' ''; return ;;
  esac
  printf '%s%s%*s\033[0m' "$color" "$txt" $((10 - ${#txt})) ''
}

# Time group label (per minute up to 1h, then hours/days)
age_label() {
  local v=$1 age
  [[ "$v" -eq 0 ]] && { echo "never"; return; }
  age=$(( $(date +%s) - v ))
  if   (( age < 60 ));    then echo "now"
  elif (( age < 3600 ));  then echo "$((age / 60))m ago"
  elif (( age < 86400 )); then echo "$((age / 3600))h ago"
  else                         echo "$((age / 86400))d ago"
  fi
}

selected=$(
  tmux list-windows -a -F '#{window_id}|#{@visited}|#{session_name}|#{window_index}|#{window_name}|#{pane_current_command}|#{pane_current_path}' |
    sort -t'|' -k2,2nr |
    { prev=""
      while IFS='|' read -r win visited session idx name cmd path; do
        [[ "$win" == "$current" ]] && continue
        label=$(age_label "${visited:-0}")
        if [[ "$label" != "$prev" ]]; then
          printf '\t\t\033[90m─── %s ──────────────────\033[0m\n' "$label"
          prev=$label
        fi
        sicon=$(~/.config/tmux/session-icon.sh "$session")
        wicon=$(cmd_icon "$cmd")
        [[ "$path" == "$HOME"* ]] && path="~${path#"$HOME"}"
        printf '%s\t%s\t  \033[33m%s\033[0m %-14s \033[0m%s\033[1m%-20s\033[0m %s \033[90m%s\033[0m\n' \
          "$win" "$session" "$sicon" "$session:$idx" "$wicon" "$name" "$(status_col "$win")" "$path"
      done; } |
  tee /tmp/tmux-windows-last.log |
  fzf --ansi --delimiter=$'\t' --with-nth=3.. --no-sort --reverse \
      --prompt="$PROMPT_INS" --header='esc: normal mode (j/k/g/G, i to search, q quits)' \
      --bind "start:unbind($VIM_KEYS)" \
      --bind "esc:rebind($VIM_KEYS)+change-prompt($PROMPT_NRM)" \
      --bind 'j:down,k:up,g:first,G:last,d:half-page-down,u:half-page-up,q:abort' \
      --bind "i:unbind($VIM_KEYS)+change-prompt($PROMPT_INS)"
) || true

[[ -n "${selected:-}" ]] || exit 0

win=$(cut -f1 <<<"$selected")
session=$(cut -f2 <<<"$selected")

# Enter on a group separator: ignore
[[ "$win" == @* ]] || exit 0

tmux switch-client -t "$session:" 2>/dev/null
tmux select-window -t "$win"
