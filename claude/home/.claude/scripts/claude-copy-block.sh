#!/usr/bin/env bash
# prefix + y — copia um bloco de código da conversa do Claude Code do pane atual.
# Lê do TRANSCRIPT (~/.claude/projects/<projeto>/<sessão>.jsonl), que guarda o
# texto exato que o Claude escreveu — sem o wrap da tela. Determinístico.
set -uo pipefail

if [[ "${1:-}" != "--popup" ]]; then
  tmux display-popup -E -w 90% -h 70% "$0 --popup"
  exit 0
fi

cwd=$(tmux display-message -p '#{pane_current_path}')
proj="$HOME/.claude/projects/${cwd//\//-}"
# fallback: projeto com transcript mais recente
[[ -d "$proj" ]] || proj=$(ls -td "$HOME"/.claude/projects/*/ 2>/dev/null | head -1)
ls "$proj"/*.jsonl >/dev/null 2>&1 || { echo "nenhum transcript em $proj"; sleep 2; exit 1; }

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

# Extrai os blocos ```...``` das mensagens do assistente de TODAS as sessões do
# projeto (pode haver mais de um claude aberto), ordenados por hora, um por arquivo.
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
blocks = blocks[-300:]                       # só os últimos 300
idx = []
for n, (ts, lang, code) in enumerate(blocks, 1):
    (out / f"{n}.txt").write_text(code, encoding="utf-8")
    first = code.strip().splitlines()[0][:80]
    idx.append(f"{n}\t{ts[11:16] or '--:--'}\t{lang:<6}\t{code.count(chr(10))+1:>3}L\t{first}")
(out / "index").write_text("\n".join(idx), encoding="utf-8")
PY2

[[ -s "$dir/index" ]] || { echo "nenhum bloco de código em $(basename "$proj")"; sleep 2; exit 1; }

# Preview com syntax highlighting (bat + gruvbox); a linguagem vem do fence.
# {3} é a coluna de linguagem do índice; "-" cai no autodetect do bat.
PREVIEW='f="'"$dir"'"/{1}.txt; l=$(printf %s {3} | tr -d " "); [ "$l" = "-" ] && l=sh;
  bat --color=always --style=plain --theme=gruvbox-dark --language="$l" "$f" 2>/dev/null || cat "$f"'

# Modo vim: começa em insert; esc entra no normal (j/k/g/G/d/u/q), i volta.
VIM_KEYS='j,k,g,G,d,u,q'
PROMPT_INS="$(printf '\xef\x84\xa1') block ❯ "
PROMPT_NRM="$(printf '\xef\x84\xa1') block [N] ❯ "

sel=$(tac "$dir/index" | fzf --ansi --delimiter=$'\t' --with-nth=2.. --no-sort --reverse \
  --prompt="$PROMPT_INS" \
  --header="$(basename "$proj") · recentes primeiro · Enter copia · esc: modo normal" \
  --preview="$PREVIEW" --preview-window=down:60%:wrap \
  --bind "start:unbind($VIM_KEYS)" \
  --bind "esc:rebind($VIM_KEYS)+change-prompt($PROMPT_NRM)" \
  --bind 'j:down,k:up,g:first,G:last,d:preview-half-page-down,u:preview-half-page-up,q:abort' \
  --bind "i:unbind($VIM_KEYS)+change-prompt($PROMPT_INS)")
[[ -n "$sel" ]] || exit 0

n=$(cut -f1 <<<"$sel")
pbcopy < "$dir/$n.txt"
lines=$(wc -l < "$dir/$n.txt" | tr -d ' ')
chars=$(wc -c < "$dir/$n.txt" | tr -d ' ')
tmux display-message "$(printf '\xef\x83\x85') copiado do transcript · $((lines+1)) linha(s) · ${chars} chars"
