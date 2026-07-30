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

decline_event() {
  local events_file=$1
  local event_id=$2
  local ical_cli
  local title
  local current_user_status
  local error_message

  title=$(
    get_event_title \
      "$events_file" \
      "$event_id"
  )

  current_user_status=$(
    get_event_current_user_status \
      "$events_file" \
      "$event_id"
  )

  if [ -z "$current_user_status" ]; then
    tmux_message "This event is not an invitation for you: $title"
    return 1
  fi

  if [ "$current_user_status" = "declined" ]; then
    tmux_message "Already declined: $title"
    return 1
  fi

  ical_cli=$(find_binary ical) || {
    tmux_message "ical was not found; install it with Homebrew to decline meetings"
    return 1
  }

  if ! error_message=$(
    "$ical_cli" \
      --no-color \
      rsvp declined \
      "$event_id" \
      2>&1
  ); then
    error_message=${error_message%%$'\n'*}

    if [ -n "$error_message" ]; then
      tmux_message "Could not decline $title: $error_message"
    else
      tmux_message "Could not decline: $title"
    fi

    return 1
  fi

  tmux_message "Declined: $title"
}
