---
name: print
description: Tira um print (screenshot) da tela do Mac e entrega a imagem, opcionalmente de uma window específica do tmux. Use quando o usuário pedir "print", "print da tela", "screenshot", "manda um print", "print da window X", "print da aba X". Só captura e entrega — sem descrever nem comentar o conteúdo.
allowed-tools: Bash, Read
---

# Print da tela

Capture a tela e entregue a imagem. **Nada além disso.**

## Uso

O script fica em `~/.claude/skills/print/print.sh` e imprime o caminho do PNG.

```bash
~/.claude/skills/print/print.sh                 # tela como está
~/.claude/skills/print/print.sh --list          # lista as windows do tmux
~/.claude/skills/print/print.sh belchior        # troca pra essa window, printa, e volta
~/.claude/skills/print/print.sh axolutions:6    # sessão:índice (desambigua nomes repetidos)
~/.claude/skills/print/print.sh --text belchior # dump em texto do pane (sem imagem)
```

Depois leia o PNG retornado com a tool Read para exibir a imagem.

## Escolhendo a window

- Sem argumento → printa o que está na tela agora.
- Com argumento → o script faz `select-window` (e `switch-client` se for outra sessão),
  ativa o terminal, captura e **volta pra window/sessão anterior**.
- Se o nome existir em mais de uma sessão, use `sessão:índice`.
- Se o usuário pedir um nome que não existe, rode `--list` e mostre as opções.

## Regras

- Não descreva o que aparece na tela.
- Não liste janelas, apps, abas ou horários.
- Não comente, não resuma, não pergunte nada.
- Nenhum texto de acompanhamento. Só a imagem.
