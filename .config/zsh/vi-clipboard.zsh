# macOS clipboard integration for ZLE vi command mode.
#
# d, x, c and y copy into the macOS clipboard.
# p and P paste from the macOS clipboard.

[[ "$OSTYPE" == darwin* ]] || return 0

typeset -g _ZLE_CLIPBOARD_TEXT=''
typeset -gi _ZLE_CLIPBOARD_OWNED=0

function _zle_clipboard_write() {
  (($+commands[pbcopy])) || return 0

  print -rn -- "$CUTBUFFER" | command pbcopy

  _ZLE_CLIPBOARD_TEXT=$CUTBUFFER
  _ZLE_CLIPBOARD_OWNED=1
}

function _zle_clipboard_read() {
  (($+commands[pbpaste])) || return 1

  local clipboard=''
  IFS= read -r -d '' clipboard < <(command pbpaste) || true

  # Preserve ZLE's linewise metadata after operations such as dd.
  if ((!_ZLE_CLIPBOARD_OWNED)) ||
    [[ $clipboard != "$_ZLE_CLIPBOARD_TEXT" ]] ||
    [[ $CUTBUFFER != "$_ZLE_CLIPBOARD_TEXT" ]]; then
    CUTBUFFER=$clipboard
    _ZLE_CLIPBOARD_TEXT=$clipboard
    _ZLE_CLIPBOARD_OWNED=0
  fi
}

function _zle_vi_change_to_clipboard() {
  zle -f vichange

  local widget=$1
  zle ".${widget}"
  local result=$?

  ((result == 0)) && _zle_clipboard_write

  return $result
}

function _zle_vi_yank_to_clipboard() {
  local widget=$1
  zle ".${widget}"
  local result=$?

  ((result == 0)) && _zle_clipboard_write

  return $result
}

function _zle_vi_put_from_clipboard() {
  zle -f vichange

  local widget=$1

  _zle_clipboard_read || true
  zle ".${widget}"
}

function zle-vi-delete-clipboard() {
  _zle_vi_change_to_clipboard vi-delete
}

function zle-vi-delete-char-clipboard() {
  _zle_vi_change_to_clipboard vi-delete-char
}

function zle-vi-backward-delete-char-clipboard() {
  _zle_vi_change_to_clipboard vi-backward-delete-char
}

function zle-vi-kill-eol-clipboard() {
  _zle_vi_change_to_clipboard vi-kill-eol
}

function zle-vi-change-clipboard() {
  _zle_vi_change_to_clipboard vi-change
}

function zle-vi-change-eol-clipboard() {
  _zle_vi_change_to_clipboard vi-change-eol
}

function zle-vi-change-whole-line-clipboard() {
  _zle_vi_change_to_clipboard vi-change-whole-line
}

function zle-vi-substitute-clipboard() {
  _zle_vi_change_to_clipboard vi-substitute
}

function zle-vi-yank-clipboard() {
  _zle_vi_yank_to_clipboard vi-yank
}

function zle-vi-yank-whole-line-clipboard() {
  _zle_vi_yank_to_clipboard vi-yank-whole-line
}

function zle-vi-put-after-clipboard() {
  _zle_vi_put_from_clipboard vi-put-after
}

function zle-vi-put-before-clipboard() {
  _zle_vi_put_from_clipboard vi-put-before
}

zle -N zle-vi-delete-clipboard
zle -N zle-vi-delete-char-clipboard
zle -N zle-vi-backward-delete-char-clipboard
zle -N zle-vi-kill-eol-clipboard
zle -N zle-vi-change-clipboard
zle -N zle-vi-change-eol-clipboard
zle -N zle-vi-change-whole-line-clipboard
zle -N zle-vi-substitute-clipboard
zle -N zle-vi-yank-clipboard
zle -N zle-vi-yank-whole-line-clipboard
zle -N zle-vi-put-after-clipboard
zle -N zle-vi-put-before-clipboard

bindkey -M vicmd 'd' zle-vi-delete-clipboard
bindkey -M vicmd 'x' zle-vi-delete-char-clipboard
bindkey -M vicmd 'X' zle-vi-backward-delete-char-clipboard
bindkey -M vicmd 'D' zle-vi-kill-eol-clipboard

bindkey -M vicmd 'c' zle-vi-change-clipboard
bindkey -M vicmd 'C' zle-vi-change-eol-clipboard
bindkey -M vicmd 'S' zle-vi-change-whole-line-clipboard
bindkey -M vicmd 's' zle-vi-substitute-clipboard

bindkey -M vicmd 'y' zle-vi-yank-clipboard
bindkey -M vicmd 'Y' zle-vi-yank-whole-line-clipboard

bindkey -M vicmd 'p' zle-vi-put-after-clipboard
bindkey -M vicmd 'P' zle-vi-put-before-clipboard
