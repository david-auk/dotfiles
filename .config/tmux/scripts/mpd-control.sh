#!/usr/bin/env bash

set -u

find_binary() {
  command -v "$1" 2>/dev/null ||
    {
      [ -x "/opt/homebrew/bin/$1" ] &&
        printf '/opt/homebrew/bin/%s\n' "$1"
    } ||
    {
      [ -x "/usr/local/bin/$1" ] &&
        printf '/usr/local/bin/%s\n' "$1"
    }
}

MPC=$(find_binary mpc) || exit 0

action="${1:-}"
client="${2:-}"

case "$action" in
toggle)
  mpc_action="toggle"
  ;;
next)
  mpc_action="next"
  ;;
previous)
  mpc_action="prev"
  ;;
*)
  exit 1
  ;;
esac

# mpc normally prints the resulting current song and playback status after
# these commands, so we can use the response from the operation itself rather
# than making another status request.
output=$(
  "$MPC" \
    --format '[[%artist% - ]%title%]|[%file%]' \
    "$mpc_action" 2>&1
)
result=$?

if ((result != 0)); then
  if [ -n "$client" ]; then
    tmux display-message -l -c "$client" " 󰝚 MPD unavailable"
  else
    tmux display-message -l " 󰝚 MPD unavailable"
  fi

  exit 0
fi

track=$(printf '%s\n' "$output" | sed -n '1p')

state=$(
  printf '%s\n' "$output" |
    sed -n 's/^\[\([^]]*\)\].*/\1/p' |
    head -n 1
)

case "$state" in
playing)
  icon=" 󰐊"
  ;;
paused)
  icon=" 󰏤"
  ;;
stopped)
  icon=" 󰓛"
  ;;
*)
  icon=" 󰝚"
  ;;
esac

if [ -n "$track" ]; then
  message="$icon  $track"
else
  message="$icon  MPD"
fi

if [ -n "$client" ]; then
  tmux display-message -l -c "$client" "$message"
else
  tmux display-message -l "$message"
fi
