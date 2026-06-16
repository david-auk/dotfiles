#!/usr/bin/env zsh

export PATH="/System/Volumes/Data/Users/david/Library/Python/3.9/bin/:/usr/local/sbin:$PATH"

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
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx

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
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

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
alias tk='tmux kill-session -a'
alias zad='ls -d */ | xargs -I {} zoxide add {}'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

sesh_picker() {
  local selected

  if [[ -n "$TMUX" ]]; then
    selected=$(
      sesh list --icons | fzf-tmux -p '80%,70%' \
        --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
        --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
        --bind 'tab:down,btab:up' \
        --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
        --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
        --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
        --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
        --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
        --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
        --preview-window 'right:55%' \
        --preview 'sesh preview {}'
    ) || return 0
  else
    selected=$(
      sesh list --icons | fzf \
        --height '70%' --layout reverse --border \
        --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
        --header '  ^a all ^t tmux ^g configs ^x zoxide ^f find' \
        --bind 'tab:down,btab:up' \
        --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
        --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
        --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
        --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
        --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
        --preview-window 'right:55%' \
        --preview 'sesh preview {}'
    ) || return 0
  fi

  [[ -n "$selected" ]] && sesh connect "$selected"
}

alias s=sesh_picker
