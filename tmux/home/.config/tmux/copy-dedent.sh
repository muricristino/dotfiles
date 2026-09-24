#!/bin/sh
# Copia a seleção do tmux pro clipboard com três ajustes:
#  1) DEDENT: remove a indentação mínima comum (mata a "margem" do Claude Code).
#  2) HEAL:   o tmux já re-junta o wrap do terminal; o que chega quebrado é o
#             soft-wrap do Claude Code, que emite \n de verdade. Dois casos:
#             (a) corte no meio de um token — a linha bate na largura de render
#                 (várias linhas no mesmo comprimento máximo): junta SEM espaço.
#             (b) corte num espaço porque a próxima palavra não cabia: junta
#                 COM espaço.
#             Quebra intencional (a palavra seguinte CABIA, ou a linha termina
#             em "\") nunca é tocada. Sem evidência de wrap, não mexe em nada.
#  3) AVISO:  mostra no status bar quanto foi copiado e quantas quebras uniu.
LC_ALL=${LC_ALL:-en_US.UTF-8}; export LC_ALL

W=$(tmux display-message -p '#{pane_width}' 2>/dev/null)
case "$W" in ''|*[!0-9]*) W=0 ;; esac

IN=$(cat)

OUT=$(printf '%s\n' "$IN" | awk -v W="$W" '
# Token de prosa: só letras (hífen ok), com um sinal de pontuação no fim.
# Qualquer coisa com dígito, aspas, barra, ponto interno etc. é código.
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
    bs[c]   = (t ~ /\\$/)                 # continuação de shell -> intencional
    lead[c] = (t ~ /^[[:space:]]/)        # indentada (após dedent) -> intencional
  }

  # Quantas linhas param no comprimento máximo (marca da coluna de render).
  nmax = 0
  for (i = 1; i <= c; i++) if (len[i] == wmax) nmax++

  # Wrap guloso consistente: se ALGUMA quebra poderia ter cabido na linha
  # anterior, ela foi intencional e o bloco não é um parágrafo quebrado.
  greedy = 1
  for (i = 1; i < c; i++) {
    if (d[i+1] == "" || bs[i] || lead[i+1]) continue
    fw = d[i+1]; sub(/[[:space:]].*/, "", fw)
    if (len[i] + 1 + length(fw) <= wmax) { greedy = 0; break }
  }

  # Evidência de que a tela quebrou o bloco. Piso de 30 colunas descarta
  # listas e textos curtos.
  wrapped = (wmax >= 30 && (nmax >= 2 || (W > 0 && wmax >= W - 6) || greedy))

  i = 1
  while (i <= c) {
    cur = d[i]; k = i                                     # k = última absorvida
    while (i < c) {
      nxt = d[i+1]
      if (nxt == "" || bs[k]) break                       # vazia ou "\" -> para
      nx = nxt; sub(/^[[:space:]]+/, "", nx)              # sem a margem/indent
      fw = nx;  sub(/[[:space:]].*/, "", fw)              # 1ª palavra da próxima

      joined = 0
      if (wrapped && len[k] >= wmax) {
        # Linha CHEIA: o corte foi no meio do token, indentação da próxima é
        # só margem de render. Exceção: prosa dos dois lados -> corte por
        # palavra que por acaso encheu a linha.
        lt = d[k]; sub(/.*[[:space:]]/, "", lt)
        sep = (plain(lt) && plain(fw)) ? " " : ""
        cur = cur sep nx; joined = 1
      } else if (wrapped && !lead[i+1] && len[k] + 1 + length(fw) > wmax) {
        cur = cur " " nxt; joined = 1                     # corte entre palavras
      } else if (len[k] >= 30 && nx !~ /[[:space:]]/) {
        # fallback URL/path: linha longa terminando num token com "/" seguida
        # de um token único (mesmo indentado) -> continuação.
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

printf '%s' "$OUT" | pbcopy

in_l=$(printf '%s\n' "$IN"  | grep -c '')
out_l=$(printf '%s'  "$OUT" | grep -c '')
chars=$(printf '%s'  "$OUT" | wc -c | tr -d ' ')
joins=$((in_l - out_l))
[ "$joins" -lt 0 ] && joins=0

icon=$(printf '\xef\x83\x85')
msg="$icon copiado · ${out_l} linha(s) · ${chars} chars"
[ "$joins" -gt 0 ] && msg="$msg · ${joins} quebra(s) unida(s)"
tmux display-message "$msg" 2>/dev/null
