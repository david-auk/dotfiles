#!/usr/bin/env bash

find_binary() {
  local name=$1

  command -v "$name" 2>/dev/null ||
    {
      [ -x "/opt/homebrew/bin/$name" ] &&
        printf '/opt/homebrew/bin/%s\n' "$name"
    } ||
    {
      [ -x "/usr/local/bin/$name" ] &&
        printf '/usr/local/bin/%s\n' "$name"
    }
}

tmux_message() {
  local message=$1

  if command -v tmux >/dev/null 2>&1; then
    tmux display-message "$message"
  else
    printf '%s\n' "$message" >&2
  fi
}
