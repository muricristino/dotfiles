#!/bin/sh
# Copies the tmux selection to the clipboard with three adjustments:
#  1) DEDENT: strips the common minimum indentation (kills Claude Code's "margin").
#  2) HEAL:   tmux already rejoins terminal wrapping; what arrives broken is
#             Claude Code's soft-wrap, which emits real \n. Two cases:
#             (a) cut mid-token — the line hits the render width (several
#                 lines at the same max length): join WITHOUT a space.
#             (b) cut at a space because the next word didn't fit: join
#                 WITH a space.
#             Intentional breaks (the next word WOULD have fit, or the line
#             ends in "\") are never touched. No wrap evidence, no changes.
#  3) NOTICE: shows in the status bar how much was copied and how many breaks were joined.
LC_ALL=${LC_ALL:-en_US.UTF-8}; export LC_ALL

W=$(tmux display-message -p '#{pane_width}' 2>/dev/null)
case "$W" in ''|*[!0-9]*) W=0 ;; esac

IN=$(cat)

OUT=$(printf '%s\n' "$IN" | awk -v W="$W" '
# Prose token: letters only (hyphen ok), with one trailing punctuation mark.
# Anything with a digit, quote, slash, inner dot etc. is code.
function plain(t,   x) {
  x = t
  sub(/[.,;:!?)]$/, "", x)
  if (x == "") return 0
  return (x !~ /[0-9.\/\\"'"'"'`=$(){}\[\]<>|&#@~*+:;,%]/)
}
{
  lines[NR] = $0
  olen[NR]  = length($0)
  if (olen[NR] > wmax) wmax = olen[NR]
  if ($0 ~ /[^ ]/) {
    n = match($0, /[^ ]/) - 1
    if (minset == 0 || n < min) { min = n; minset = 1 }
  }
}
END {
  if (minset == 0) min = 0

  c = 0
  for (i = 1; i <= NR; i++) {
    t = substr(lines[i], min + 1)
    sub(/[[:space:]]+$/, "", t)
    c++; d[c] = t
    len[c]  = olen[i]
    bs[c]   = (t ~ /\\$/)                 # shell continuation -> intentional
    lead[c] = (t ~ /^[[:space:]]/)        # indented (after dedent) -> intentional
  }

  # How many lines stop at the max length (marks the render column).
  nmax = 0
  for (i = 1; i <= c; i++) if (len[i] == wmax) nmax++

  # Consistent greedy wrap: if ANY break could have fit on the previous
  # line, it was intentional and the block is not a wrapped paragraph.
  greedy = 1
  for (i = 1; i < c; i++) {
    if (d[i+1] == "" || bs[i] || lead[i+1]) continue
    fw = d[i+1]; sub(/[[:space:]].*/, "", fw)
    if (len[i] + 1 + length(fw) <= wmax) { greedy = 0; break }
  }

  # Evidence that the screen wrapped the block. A 30-column floor rules out
  # lists and short text.
  wrapped = (wmax >= 30 && (nmax >= 2 || (W > 0 && wmax >= W - 6) || greedy))

  i = 1
  while (i <= c) {
    cur = d[i]; k = i                                     # k = last absorbed
    while (i < c) {
      nxt = d[i+1]
      if (nxt == "" || bs[k]) break                       # empty or "\" -> stop
      nx = nxt; sub(/^[[:space:]]+/, "", nx)              # without margin/indent
      fw = nx;  sub(/[[:space:]].*/, "", fw)              # first word of next line

      joined = 0
      if (wrapped && len[k] >= wmax) {
        # FULL line: the cut was mid-token, the indentation of the next line is
        # just render margin. Exception: prose on both sides -> a word-boundary
        # cut that happened to fill the line.
        lt = d[k]; sub(/.*[[:space:]]/, "", lt)
        sep = (plain(lt) && plain(fw)) ? " " : ""
        cur = cur sep nx; joined = 1
      } else if (wrapped && !lead[i+1] && len[k] + 1 + length(fw) > wmax) {
        cur = cur " " nxt; joined = 1                     # cut between words
      } else if (len[k] >= 30 && nx !~ /[[:space:]]/) {
        # URL/path fallback: long line ending in a token with "/" followed
        # by a single token (even if indented) -> continuation.
        lt = cur; sub(/.*[[:space:]]/, "", lt)
        if (lt ~ /\//) { cur = cur nx; joined = 1 }
      }
      if (!joined) break
      i++; k = i
    }
    print cur
    i++
  }
}')

printf '%s' "$OUT" | ~/.config/tmux/clip.sh copy

in_l=$(printf '%s\n' "$IN"  | grep -c '')
out_l=$(printf '%s'  "$OUT" | grep -c '')
chars=$(printf '%s'  "$OUT" | wc -c | tr -d ' ')
joins=$((in_l - out_l))
[ "$joins" -lt 0 ] && joins=0

icon=$(printf '\xef\x83\x85')
msg="$icon copied · ${out_l} line(s) · ${chars} chars"
[ "$joins" -gt 0 ] && msg="$msg · ${joins} break(s) joined"
tmux display-message "$msg" 2>/dev/null
