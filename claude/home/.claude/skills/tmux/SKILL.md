---
name: tmux
description: Inspects and drives tmux panes — list windows/panes, read what's on a pane's screen, find and repeat the last command run there, send commands or keys. Use when the user talks about a "pane", "window", "tmux tab", "run it again in pane X", "what's running in Y", "send C-c to pane Z".
allowed-tools: Bash
---

# tmux

Script: `~/.claude/skills/tmux/tmux.sh`. The target is always `session:window.pane` (e.g. `rd:1.2`).

```bash
T=~/.claude/skills/tmux/tmux.sh

$T ls                       # all windows of all sessions
$T panes rd:1               # the window's panes, with running command and cwd
$T cat rd:1.2 80            # last 80 lines of the pane
$T hist rd:1.2 hoop         # commands already run in the pane matching "hoop"
$T last rd:1.2 hoop         # the last of them
$T run rd:1.2 'hoop login'  # send the command + Enter and show the result
$T rerun rd:1.2 hoop        # repeat the last command matching "hoop"
$T keys rd:1.2 C-c          # raw keys: C-c, Escape, q, Up...
```

## Resolving the target

If the user only gives a name ("pane 2 of api"), run `$T ls` to find
`session:window` and build `session:window.pane`. Same name in different sessions
(e.g. `api` in work:1, work:7, work:8) → confirm with `$T panes`.

## Notes

- `run` waits 4s by default before capturing; pass a 3rd argument to wait longer
  (`$T run rd:1.2 'heavy command' 15`).
- `hist`/`last` read the scrollback (5000 lines) looking for prompt lines `❯ $ #`.
  If the pane was cleared, fall back to `~/.zsh_history`.
- An interactive command (login that opens a browser, TUI) hangs in the pane —
  capture again later instead of waiting in the shell.
