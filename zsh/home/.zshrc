# Homebrew (macOS Apple Silicon/Intel, or Linux)
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [ -x "$brew" ] && { eval "$("$brew" shellenv)"; break; }
done

# asdf
[ -n "$HOMEBREW_PREFIX" ] && [ -f "$HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh" ] && . "$HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh"

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="refined"

plugins=(git vi-mode zsh-syntax-highlighting zsh-autosuggestions)

# vi-mode cursor shapes (deve vir antes do source omz)
VI_MODE_SET_CURSOR=true
MODE_CURSOR_VICMD="steady block"
MODE_CURSOR_VIINS="steady bar"
MODE_CURSOR_SEARCH="steady underline"

source $ZSH/oh-my-zsh.sh

# Comentários: o padrão do plugin é fg=black (cor 0), ilegível no fundo escuro
ZSH_HIGHLIGHT_STYLES[comment]='fg=#928374'

# Shift+Enter (ESC+CR, vindo do keybind do Ghostty): quebra linha sem executar
_insert_newline() { LBUFFER+=$'\n' }
zle -N _insert_newline
bindkey -M viins '^[^M' _insert_newline
bindkey -M vicmd '^[^M' _insert_newline
bindkey -M emacs '^[^M' _insert_newline

# Cmd+V chega como ^V (keybind do Ghostty): cola o clipboard no buffer.
# O quoted-insert original (inserir caractere literal) migra pro ^Q.
if (( $+commands[pbpaste] )); then
  _paste_clipboard() { LBUFFER+="$(pbpaste)" }
  zle -N _paste_clipboard
  bindkey -M viins '^V' _paste_clipboard
  bindkey -M vicmd '^V' _paste_clipboard
  bindkey -M emacs '^V' _paste_clipboard
  bindkey -M viins '^Q' vi-quoted-insert
  bindkey -M emacs '^Q' quoted-insert
fi

# Editor
export EDITOR='nvim'
export RUBYOPT="-EUTF-8"

# PATH
export PATH="$HOME/.asdf/shims:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export QLTY_INSTALL="$HOME/.qlty"
export PATH="$QLTY_INSTALL/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# qlty completions
[ -s "$HOMEBREW_PREFIX/share/zsh/site-functions/_qlty" ] && source "$HOMEBREW_PREFIX/share/zsh/site-functions/_qlty"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Aliases
if (( $+commands[eza] )); then
  unalias ls 2>/dev/null
  alias ls="eza --icons --git -a --group-directories-first"
  alias ll="eza --icons --git -la --group-directories-first"
fi
alias s="ls"
alias yolo="claude --dangerously-skip-permissions"

# Mata todos os processos escutando em portas TCP
function chacina() {
  local pids=$(lsof -tiTCP -sTCP:LISTEN | sort -u)
  if [[ -z "$pids" ]]; then
    echo "Nenhum processo escutando portas."
  else
    echo "Matando processos na porta:\n$pids"
    kill -9 ${(f)pids}
    echo "Feito."
  fi

  # Mata copilot-language-server zumbis (mantém só o mais recente)
  local copilot_pids=(${(f)$(pgrep -f "copilot-language-server" | sort -n)})
  local count=${#copilot_pids}
  if [[ $count -gt 1 ]]; then
    local zombies=(${copilot_pids[1,-2]})
    echo "Matando $((count - 1)) copilot zumbi(s): $zombies"
    kill -9 ${zombies[@]}
  fi
}

# Edit PR description in nvim
function pre() {
  local tmp=$(mktemp /tmp/pr-body-XXXX.md)
  gh pr view --json body -q .body > "$tmp"
  nvim "$tmp"
  gh pr edit --body-file "$tmp"
  rm "$tmp"
}

# Force colors
unset NO_COLOR
unset FORCE_COLOR

# Load local secrets (not tracked in git)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
