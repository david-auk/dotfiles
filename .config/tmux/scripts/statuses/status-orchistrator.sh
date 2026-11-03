#!/usr/bin/env bash

set -u

statuses=(
  "$HOME/.config/tmux/scripts/statuses/daily-tasks-status.sh"
  "$HOME/.config/tmux/scripts/statuses/meeting-status.sh"
)

separator='#[fg=#6c7086]│#[default]'

visible=()

for script in "${statuses[@]}"; do
  [ -x "$script" ] || continue

  output=$("$script" 2>/dev/null) || continue

  [ -n "$output" ] || continue

  visible+=("$output")
done

for ((i = 0; i < ${#visible[@]}; i++)); do
  if ((i > 0)); then
    printf ' %s ' "$separator"
  fi

  printf '%s ' "${visible[$i]}"
done
