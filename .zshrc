#!/usr/bin/env bash

alias ls="ls -G"
#autoload -Uz backeted-paste-magic
#zle -N bracketed-paste bracketed-paste-magic
autoload -Uz compinit
compinit

SCRIPT_DIR="$HOME/.zshrc_scripts"

config=
if [[ $config == "" ]]; then
  prompt=default
  lscolo=pi
fi

if [[ $config == "pi" ]]; then
  prompt=pi
  lscolo=pi
fi
if [[ $config == "default" ]]; then
  prompt=default
  lscolo=default
fi

if [[ $prompt == "default" ]]; then
  PROMPT='%n@%m %1~ %# '
fi
if [[ $lscolo == "default" ]]; then
  export CLICOLOR=0
fi

if [[ $prompt == "pi" ]]; then
  PROMPT="%B%F{green}%n@%m%f%b:%B%F{blue}%~ $ %f%b"
fi
if [[ $lscolo == "pi" ]]; then
  export CLICOLOR=1
  export LSCOLORS=ExGxCxDxCxegedabagaced
fi

export VISUAL=nvim
export EDITOR=nvim

autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

unsetopt nomatch
export PATH="/System/Volumes/Data/Users/david/Library/Python/3.9/bin/:/usr/local/sbin:$PATH"
alias ll="ls -alrth"
alias ip="ipconfig getifaddr en0"
alias da="gdate  '+%d/%m/%Y'|tr -d [:space:]|pbcopy;gdate  '+%d/%m/%Y'"
alias sed=gsed
alias venv='source venv/bin/activate'
alias ww="pw=\$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+=' </dev/urandom | head -c 16); echo \"Coppied: \$pw\"; echo -n \$pw | pbcopy"
alias code="open -a Visual\ Studio\ Code"

# Git
git-url() {
  # 1) Make sure we’re in a git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not a git repository." >&2
    return 1
  fi

  # 2) Grab origin
  local remote url branch sha
  if ! remote=$(git remote get-url origin 2>/dev/null); then
    echo "No 'origin' remote found." >&2
    return 1
  fi

  # 3) Normalize to https and strip .git
  case "$remote" in
  git@*:*)
    # git@host:owner/repo.git → https://host/owner/repo
    url=$(echo "$remote" | sed -e 's|:|/|' -e 's|git@|https://|' -e 's|\.git$||')
    ;;
  ssh://git@*/*)
    # ssh://git@host/owner/repo.git → https://host/owner/repo
    url="${remote#ssh://git@}" # host/owner/repo.git
    url="https://${url}"
    ;;
  http://* | https://*)
    # already http(s)
    url="$remote"
    ;;
  *)
    # fallback
    url="$remote"
    ;;
  esac
  url="${url%.git}" # drop trailing ".git"

  # 4) Figure out branch (or short SHA if detached)
  branch=$(git symbolic-ref --short -q HEAD) || true
  if [ -z "$branch" ]; then
    sha=$(git rev-parse --short HEAD)
    branch="$sha"
  fi

  # 5) Print the full “tree” URL
  echo "${url}/tree/${branch}"
}

git-prune-branches() {
  b_white='\033[1m'
  nc='\033[0m'

  working_branch=$(git branch | grep "^* " | sed -e "s|^\* ||g")

  # Switch to main/master
  if [[ "$working_branch" != "main" && "$working_branch" != "master" ]]; then
    echo -e "${b_white}Switching to master or main branch...$nc"
    git branch | grep -e '^  main$' -e '^  master$' | xargs -n 1 git checkout
    echo "" # Newline for formatting
  fi

  # Fetch from remote
  echo -e "${b_white}Fetching with -p option...$nc"
  git fetch -p
  echo "" # Newline for formatting

  # Cleanup remotely deleted branches localy
  echo -e "${b_white}Running pruning of local branches...$nc"
  git branch -vv | grep ': gone]' | grep -v "*" | awk '{ print $1; }' | xargs -r git branch -D
  echo "" # Newline for formatting

  # Switch back to old working branch (if relevant)
  if $(git branch | grep "^  $working_branch$" &>/dev/null) && [[ "$working_branch" != "main" && "$working_branch" != "master" ]]; then
    echo -e "\n${b_white}Switching back to original branch...$nc"
    git checkout "$working_branch"
    echo "" # Newline for formatting
  fi
}

#alias git-url='git remote get-url origin|sed -e "s|git@|https://|"|sed -e "s|.com:|.com/|"|sed -e "s/.git$//"'

# Docker

alias dc="docker compose"

# Signal

alias s="gurk"

# Define a custom completion function for the mdt alias
_mdt() {
  local -a args
  args=(${(f)${(qq)BUFFER}})
  _files -W $PWD -g "*.(md|markdown)" $args[-1]
}

# Set the custom completion function for the mdt alias
compdef _mdt mdt
#alias star='eval "$(starship init $SHELL)"'

# Dotfiles configuration #

dot() { /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME "$@"; }
dot-conf-local() { /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config --local "$@"; }
dot-conf-shared() { /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config --file "$HOME/.dotfiles/config.shared" "$@"; }

_dot_complete() {
  local saved_words=("${words[@]}")
  local saved_current=$CURRENT

  words=(git "${saved_words[@]:1}")

  # Tell git completion which repo to query for file/branch/ref lookups
  local -x GIT_DIR="$HOME/.dotfiles"
  local -x GIT_WORK_TREE="$HOME"

  _normal

  words=("${saved_words[@]}")
  CURRENT=$saved_current
}

_dot_conf_complete() {
  local saved_words=("${words[@]}")
  local saved_current=$CURRENT

  # dot-conf-local -> git config (1 word for 2 words, CURRENT shifts +1)
  words=(git config "${saved_words[@]:1}")
  CURRENT=$((saved_current + 1))

  _normal

  words=("${saved_words[@]}")
  CURRENT=$saved_current
}

compdef _dot_complete dot
compdef _dot_conf_complete dot-conf-local dot-conf-shared

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

#if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ]; then
#    tmux new-session -A -s main
#fi

alias vim="nvim"
alias vi="vim"

# Fix normal shell keybindings (C-A, C-a, C-r)
bindkey -e

# Tmux bindigns

alias ta="tmux attach"
alias tn="tmux new-session -A -s \"$(date +%m/%d-%H_%M)\""
alias tl="tmux ls"
alias tk="tmux kill-session -a"

# autostart in tmux
# Only show in real interactive shells, not inside tmux
if [[ -o interactive && -z "$TMUX" ]]; then
  choice=$(gum choose \
    "Quick create new tmux session" \
    "Attach latest tmux session" \
    "Create new tmux session" \
    "Continue without tmux")

  case "$choice" in
  "Quick create new tmux session")
    tn
    ;;
  "Attach latest tmux session")
    latest=$(tmux list-sessions -F '#{session_last_attached} #{session_name}' 2>/dev/null |
      sort -nr |
      head -n1 |
      cut -d' ' -f2-)

    if [[ -n "$latest" ]]; then
      exec tmux attach-session -t "$latest"
    else
      fallback=$(gum choose \
        "Create new tmux session" \
        "Continue without tmux" \
        --header "No tmux sessions found")

      case "$fallback" in
      "Create new tmux session")
        name=$(gum input --placeholder "Session name")
        if [[ -n "$name" ]]; then
          exec tmux new-session -s "$name"
        else
          exec tmux new-session
        fi
        ;;
      "Continue without tmux")
        ;;
      esac
    fi
    ;;
  "Create new tmux session")
    name=$(gum input --placeholder "Session name")
    if [[ -n "$name" ]]; then
      exec tmux new-session -s "$name"
    else
      exec tmux new-session
    fi
    ;;

  "Continue without tmux")
    ;;
  esac
fi
