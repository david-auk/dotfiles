#!/usr/bin/env bash

fetch_today_events() {
  "$ICAL_GUY" events \
    --from today \
    --group-by none \
    --format json \
    --no-color \
    2>/dev/null
}

count_visible_events() {
  local events_file=$1

  "$JQ" '
    [
      .[]
      | select((.status // "") != "canceled")
    ]
    | length
  ' "$events_file"
}

find_default_event_position() {
  local events_file=$1
  local now_epoch

  now_epoch=$(date +%s)

  "$JQ" -r \
    --argjson now "$now_epoch" '
      def epoch:
        sub("\\.[0-9]+Z$"; "Z")
        | fromdateiso8601;

      [
        .[]
        | select((.status // "") != "canceled")
      ]
      | sort_by(.startDate)
      | to_entries
      | (
          map(
            select(
              ((.value.isAllDay // false) == false)
              and
              (
                (.value.endDate | epoch) > $now
              )
            )
          )
          | first
        )
      | if . == null then
          1
        else
          (.key + 1)
        end
    ' "$events_file"
}

get_event_title() {
  local events_file=$1
  local event_id=$2

  "$JQ" -r \
    --arg event_id "$event_id" '
      first(
        .[]
        | select(.id == $event_id)
        | .title
      ) // "(untitled)"
    ' "$events_file"
}

get_event_meeting_url() {
  local events_file=$1
  local event_id=$2

  "$JQ" -r \
    --arg event_id "$event_id" '
      first(
        .[]
        | select(.id == $event_id)
        | .meetingUrl
      ) // empty
    ' "$events_file"
}

get_event_json() {
  local events_file=$1
  local event_id=$2

  "$JQ" \
    --arg event_id "$event_id" '
      first(
        .[]
        | select(.id == $event_id)
      )
    ' "$events_file"
}

get_attendee_summary() {
  local events_file=$1
  local event_id=$2

  "$JQ" \
    --arg event_id "$event_id" '
      first(
        .[]
        | select(.id == $event_id)
      )
      | (.attendees // []) as $attendees
      | {
          total: ($attendees | length),
          accepted: (
            [
              $attendees[]
              | select(.status == "accepted")
            ]
            | length
          ),
          tentative: (
            [
              $attendees[]
              | select(.status == "tentative")
            ]
            | length
          ),
          declined: (
            [
              $attendees[]
              | select(.status == "declined")
            ]
            | length
          ),
          pending: (
            [
              $attendees[]
              | select(
                  .status != "accepted"
                  and .status != "tentative"
                  and .status != "declined"
                )
            ]
            | length
          )
        }
    ' "$events_file"
}
