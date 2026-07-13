#!/usr/bin/env bash

colorize_calendar() {
  local text=$1
  local hex=${2#\#}

  if [[ "$hex" =~ ^[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$ ]]; then
    hex=${hex:0:6}

    local red=$((16#${hex:0:2}))
    local green=$((16#${hex:2:2}))
    local blue=$((16#${hex:4:2}))

    printf '\033[38;2;%d;%d;%dm%s\033[0m' \
      "$red" \
      "$green" \
      "$blue" \
      "$text"
  else
    printf '%s' "$text"
  fi
}

build_event_rows() {
  local events_file=$1

  "$JQ" -r '
    def epoch:
      sub("\\.[0-9]+Z$"; "Z")
      | fromdateiso8601;

    [
      .[]
      | select((.status // "") != "canceled")
    ]
    | sort_by(.startDate)
    | .[]
    | [
        (.startDate | epoch | tostring),
        (.endDate | epoch | tostring),
        (.isAllDay | tostring),
        (
          .title // "(untitled)"
          | gsub("[\t\r\n]"; " ")
        ),
        (
          .calendar.title // ""
          | gsub("[\t\r\n]"; " ")
        ),
        (.calendar.color // ""),
        (.meetingUrl // ""),
        (
          [
            (.attendees // [])[]
            | select(.status == "accepted")
          ]
          | length
          | tostring
        ),
        (
          (.attendees // [])
          | length
          | tostring
        ),
        (.id // "")
      ]
    | join("\u001f")
  ' "$events_file" |
    while IFS=$'\x1f' read -r \
      start_epoch \
      end_epoch \
      is_all_day \
      title \
      calendar \
      calendar_color \
      meeting_url \
      accepted_count \
      attendee_count \
      event_id; do

      if [ "$is_all_day" = "true" ]; then
        time_label="All day"
      else
        start_time=$(date -r "$start_epoch" '+%H:%M')
        end_time=$(date -r "$end_epoch" '+%H:%M')
        time_label="${start_time}–${end_time}"
      fi

      if [ -n "$meeting_url" ]; then
        meeting_indicator="󰍉"
      else
        meeting_indicator=" "
      fi

      if [ "$attendee_count" -gt 0 ]; then
        attendee_label=" 󰡉 ${accepted_count}/${attendee_count}"
      else
        attendee_label=""
      fi

      calendar_label=$(
        colorize_calendar "[$calendar]" "$calendar_color"
      )

      display=$(
        printf '%-13s %s %s%s - %s' \
          "$time_label" \
          "$meeting_indicator" \
          "$title" \
          "$attendee_label" \
          "$calendar_label"
      )

      # Keep the event ID in a hidden fzf field.
      printf '%s\t%s\n' \
        "$display" \
        "$event_id"
    done
}
