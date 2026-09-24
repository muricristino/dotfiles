---
name: tmux
description: Inspeciona e dirige panes do tmux — listar windows/panes, ler o que está na tela de um pane, descobrir e repetir o último comando rodado ali, mandar comandos ou teclas. Use quando o usuário falar de "pane", "window", "aba do tmux", "roda de novo lá no pane X", "o que tá rodando no Y", "manda C-c no pane Z".
allowed-tools: Bash
---

# tmux

Script: `~/.claude/skills/tmux/tmux.sh`. Alvo é sempre `sessão:window.pane` (ex.: `rd:1.2`).

```bash
T=~/.claude/skills/tmux/tmux.sh

$T ls                       # todas as windows de todas as sessões
$T panes rd:1               # panes da window, com comando rodando e cwd
$T cat rd:1.2 80            # últimas 80 linhas do pane
$T hist rd:1.2 hoop         # comandos já rodados no pane que casam com "hoop"
$T last rd:1.2 hoop         # o último deles
$T run rd:1.2 'hoop login'  # manda o comando + Enter e mostra o resultado
$T rerun rd:1.2 hoop        # repete o último comando que casa com "hoop"
$T keys rd:1.2 C-c          # teclas cruas: C-c, Escape, q, Up...
```

## Como resolver o alvo

Se o usuário disser só o nome ("pane 2 do api"), rode `$T ls` pra achar
`sessão:window` e monte `sessão:window.pane`. Nome repetido em sessões diferentes
(ex.: `api` em work:1, work:7, work:8) → confirme pelo `$T panes`.

## Notas

- `run` espera 4s por padrão antes de capturar; passe um 3º argumento pra esperar mais
  (`$T run rd:1.2 'comando pesado' 15`).
- `hist`/`last` leem o scrollback (5000 linhas) procurando linhas de prompt `❯ $ #`.
  Se o pane foi limpo, caia pro `~/.zsh_history`.
- Comando interativo (login que abre browser, TUI) fica pendurado no pane —
  capture de novo depois em vez de esperar no shell.
