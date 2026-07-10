#!/usr/bin/env zsh

export PATH="/System/Volumes/Data/Users/david/Library/Python/3.9/bin/:/usr/local/sbin:$PATH"
export PATH="$PATH:$(go env GOPATH)/bin"

# Add the path for UV
export PATH="/Users/david/.local/bin:$PATH"
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-completions

# Add in snippets
# zinit snippet OMZL::git.zsh
# zinit snippet OMZP::git
# # zinit snippet OMZP::sudo
# zinit snippet OMZP::aws
# zinit snippet OMZP::kubectl
# zinit snippet OMZP::kubectx

# Load completions
autoload -Uz compinit
compinit

# fzf-tab needs to load after compinit, but before autosuggestions and syntax highlighting
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

zinit cdreplay -q

eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

# Keybindings
bindkey -v

KEYTIMEOUT=1

autoload -Uz add-zle-hook-widget

function cursor-shape-update() {
  if [[ $KEYMAP == vicmd ]]; then
    printf '\e[2 q' # block
  else
    printf '\e[6 q' # beam
  fi
}

function cursor-shape-init() {
  printf '\e[6 q'
}

function cursor-shape-precmd() {
  printf '\e[6 q'
}

add-zle-hook-widget keymap-select cursor-shape-update
add-zle-hook-widget line-init cursor-shape-init

autoload -Uz add-zsh-hook
add-zsh-hook precmd cursor-shape-precmd

# Vi insert mode bindings
bindkey -M viins '^p' history-search-backward
bindkey -M viins '^n' history-search-forward
bindkey -M viins '^f' autosuggest-accept
bindkey -M viins '^a' beginning-of-line
bindkey -M viins '^e' end-of-line

# Remove unwanted Alt/Esc+h man-page binding if it exists
bindkey -r '^[h' 2>/dev/null

# Treat `/` as a word boundary so Esc/Alt+Backspace removes one path segment
WORDCHARS=${WORDCHARS//\//}

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Defaults
EDITOR='nvim'

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' fzf-flags --ansi
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'CLICOLOR_FORCE=1 ls -G "$realpath"'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'CLICOLOR_FORCE=1 ls -G "$realpath"'

# Aliases
alias ls="ls -G"
alias ll="ls -al"
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias tk='tmux kill-session -a'
alias zad='ls -d */ | xargs -I {} zoxide add {}'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Final Ctrl-r behavior (after shell integrations)
bindkey -M viins '^r' fzf-history-widget
bindkey -M vicmd '^r' redo

alias s='~/.config/sesh/scripts/sesh_picker'
