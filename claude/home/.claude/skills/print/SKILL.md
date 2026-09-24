---
name: print
description: Takes a screenshot of the Mac screen and delivers the image, optionally of a specific tmux window. Use when the user asks for a "print", "screenshot", "screen grab", "send me a screenshot", "screenshot of window X", "screenshot of tab X". Only captures and delivers — no describing or commenting on the content.
allowed-tools: Bash, Read
---

# Screenshot

Capture the screen and deliver the image. **Nothing else.**

## Usage

The script lives at `~/.claude/skills/print/print.sh` and prints the PNG path.

```bash
~/.claude/skills/print/print.sh                 # screen as it is
~/.claude/skills/print/print.sh --list          # list the tmux windows
~/.claude/skills/print/print.sh belchior        # switch to that window, capture, and switch back
~/.claude/skills/print/print.sh axolutions:6    # session:index (disambiguates repeated names)
~/.claude/skills/print/print.sh --text belchior # text dump of the pane (no image)
```

Then read the returned PNG with the Read tool to display the image.

## Picking the window

- No argument → captures what's on screen right now.
- With an argument → the script runs `select-window` (and `switch-client` if it's another session),
  activates the terminal, captures, and **switches back to the previous window/session**.
- If the name exists in more than one session, use `session:index`.
- If the user asks for a name that doesn't exist, run `--list` and show the options.

## Rules

- Don't describe what's on screen.
- Don't list windows, apps, tabs or times.
- Don't comment, summarize, or ask anything.
- No accompanying text. Just the image.
