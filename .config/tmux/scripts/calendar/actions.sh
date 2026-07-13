#!/usr/bin/env bash

open_event_meeting() {
  local events_file=$1
  local event_id=$2
  local meeting_url
  local title

  meeting_url=$(
    get_event_meeting_url \
      "$events_file" \
      "$event_id"
  )

  title=$(
    get_event_title \
      "$events_file" \
      "$event_id"
  )

  if [ -z "$meeting_url" ]; then
    tmux_message "No meeting link for: $title"
    return 1
  fi

  if ! /usr/bin/open "$meeting_url" >/dev/null 2>&1; then
    tmux_message "Could not open meeting for: $title"
    return 1
  fi
}
