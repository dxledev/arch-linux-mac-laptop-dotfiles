# ~/.zshrc

# Only run in interactive shells
[[ -o interactive ]] || return

# Source your existing modular files (works the same)
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases
[[ -f ~/.bash_env ]] && source ~/.bash_env
[[ -f ~/.bash_functions ]] && source ~/.bash_functions
[[ -f /home/dxle/bin/dev/react/react-generate-files-wrapper ]] && source /home/dxle/bin/dev/react/react-generate-files-wrapper

# -------------------------
# Zsh completion system
# -------------------------
autoload -Uz compinit
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${ZSH_COMPDUMP:h}"
if [[ -n "$ZSH_COMPDUMP"(#qN.mh+24) ]]; then
  compinit -d "$ZSH_COMPDUMP"
else
  compinit -C -d "$ZSH_COMPDUMP"
fi

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Better completion behavior
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''

# -------------------------
# Keybindings (replacement for bind)
# -------------------------

# Use emacs-style keybindings (closest to your bash setup)
bindkey -e

# Word movement
bindkey '^[w' forward-word
bindkey '^[b' backward-word

# Start / End of line
bindkey '^[0' beginning-of-line
bindkey '^[e' end-of-line

# Delete word forward
bindkey '^[d' kill-word

# Tab completion behavior (menu-like)
bindkey '^I' menu-complete
bindkey '^[Z' reverse-menu-complete

# -------------------------
# History (better than bash defaults)
# -------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt sharehistory
setopt histignorealldups
setopt autocd
setopt interactivecomments

# -------------------------
# fzf (Zsh version)
# -------------------------
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# -------------------------
# Starship prompt
# -------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

TRAPUSR1() {
  zle && zle reset-prompt
  return 0
}

if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  ZSH_HIGHLIGHT_STYLES[arg0]='fg=default'
  ZSH_HIGHLIGHT_STYLES[command]='fg=default'
  ZSH_HIGHLIGHT_STYLES[precommand]='fg=default'
fi


# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/dxle/.lmstudio/bin"
# End of LM Studio CLI section

if [[ -z "${SSH_AUTH_SOCK:-}" || ! -S "$SSH_AUTH_SOCK" ]]; then
  unset SSH_AUTH_SOCK
  latest_agent_socket=("$HOME"/.ssh/agent/*(N.om[1]))
  if [[ -S "${latest_agent_socket[1]:-}" ]]; then
    export SSH_AUTH_SOCK="${latest_agent_socket[1]}"
  fi
  unset latest_agent_socket
fi

if [[ -r /usr/share/nvm/init-nvm.sh ]]; then
  _NVM_INIT=/usr/share/nvm/init-nvm.sh
elif [[ -r "$HOME/.nvm/nvm.sh" ]]; then
  _NVM_INIT="$HOME/.nvm/nvm.sh"
else
  _NVM_INIT=
fi

if [[ -n "$_NVM_INIT" ]]; then
  load-nvm() {
    unset -f load-nvm nvm node npm npx
    source "$_NVM_INIT"
  }

  nvm() {
    load-nvm || return
    nvm "$@"
  }

  node() {
    load-nvm || return
    node "$@"
  }

  npm() {
    load-nvm || return
    npm "$@"
  }

  npx() {
    load-nvm || return
    npx "$@"
  }
fi


# Added by Antigravity CLI installer
export PATH="/home/dxle/.local/bin:$PATH"
