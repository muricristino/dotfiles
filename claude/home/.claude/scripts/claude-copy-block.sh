#!/usr/bin/env bash
# prefix + y — copy a code block from the current pane's Claude Code conversation.
# Reads from the TRANSCRIPT (~/.claude/projects/<project>/<session>.jsonl), which holds
# the exact text Claude wrote — without screen wrapping. Deterministic.
set -uo pipefail

if [[ "${1:-}" != "--popup" ]]; then
  tmux display-popup -E -w 90% -h 70% "$0 --popup"
  exit 0
fi

cwd=$(tmux display-message -p '#{pane_current_path}')
proj="$HOME/.claude/projects/${cwd//\//-}"
# fallback: project with the most recent transcript
[[ -d "$proj" ]] || proj=$(ls -td "$HOME"/.claude/projects/*/ 2>/dev/null | head -1)
ls "$proj"/*.jsonl >/dev/null 2>&1 || { echo "no transcript in $proj"; sleep 2; exit 1; }

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

# Extract ```...``` blocks from assistant messages across ALL of the project's
# sessions (more than one claude may be open), sorted by time, one per file.
python3 - "$proj" "$dir" <<'PY2'
import json, re, sys, pathlib, glob
proj, out = sys.argv[1], pathlib.Path(sys.argv[2])
fence = re.compile(r"```([^\n]*)\n(.*?)```", re.S)
blocks = []
for f in glob.glob(proj + "/*.jsonl"):
    for line in open(f, encoding="utf-8", errors="replace"):
        try: m = json.loads(line)
        except: continue
        if m.get("type") != "assistant": continue
        ts = m.get("timestamp", "")
        for part in m.get("message", {}).get("content", []):
            if part.get("type") != "text": continue
            for lang, code in fence.findall(part["text"]):
                code = code.rstrip("\n")
                if code.strip(): blocks.append((ts, lang.strip() or "-", code))
blocks.sort(key=lambda b: b[0])
blocks = blocks[-300:]                       # only the last 300
idx = []
for n, (ts, lang, code) in enumerate(blocks, 1):
    (out / f"{n}.txt").write_text(code, encoding="utf-8")
    first = code.strip().splitlines()[0][:80]
    idx.append(f"{n}\t{ts[11:16] or '--:--'}\t{lang:<6}\t{code.count(chr(10))+1:>3}L\t{first}")
(out / "index").write_text("\n".join(idx), encoding="utf-8")
PY2

[[ -s "$dir/index" ]] || { echo "no code blocks in $(basename "$proj")"; sleep 2; exit 1; }

# Preview with syntax highlighting (bat + gruvbox); the language comes from the fence.
# {3} is the index's language column; "-" falls through to bat's autodetect.
PREVIEW='f="'"$dir"'"/{1}.txt; l=$(printf %s {3} | tr -d " "); [ "$l" = "-" ] && l=sh;
  bat --color=always --style=plain --theme=gruvbox-dark --language="$l" "$f" 2>/dev/null || cat "$f"'

# Vim mode: starts in insert; esc enters normal (j/k/g/G/d/u/q), i goes back.
VIM_KEYS='j,k,g,G,d,u,q'
PROMPT_INS="$(printf '\xef\x84\xa1') block ❯ "
PROMPT_NRM="$(printf '\xef\x84\xa1') block [N] ❯ "

sel=$(tac "$dir/index" | fzf --ansi --delimiter=$'\t' --with-nth=2.. --no-sort --reverse \
  --prompt="$PROMPT_INS" \
  --header="$(basename "$proj") · newest first · Enter copies · esc: normal mode" \
  --preview="$PREVIEW" --preview-window=down:60%:wrap \
  --bind "start:unbind($VIM_KEYS)" \
  --bind "esc:rebind($VIM_KEYS)+change-prompt($PROMPT_NRM)" \
  --bind 'j:down,k:up,g:first,G:last,d:preview-half-page-down,u:preview-half-page-up,q:abort' \
  --bind "i:unbind($VIM_KEYS)+change-prompt($PROMPT_INS)")
[[ -n "$sel" ]] || exit 0

n=$(cut -f1 <<<"$sel")
~/.config/tmux/clip.sh copy < "$dir/$n.txt"
lines=$(wc -l < "$dir/$n.txt" | tr -d ' ')
chars=$(wc -c < "$dir/$n.txt" | tr -d ' ')
tmux display-message "$(printf '\xef\x83\x85') copied from transcript · $((lines+1)) line(s) · ${chars} chars"
