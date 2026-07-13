#!/usr/bin/env bash

build_event_details() {
  local events_file=$1
  local event_id=$2
  local fields
  local notes

  fields=$(
    "$JQ" -r \
      --arg event_id "$event_id" '
        def epoch:
          sub("\\.[0-9]+Z$"; "Z")
          | fromdateiso8601;

        def clean:
          if . == null then
            ""
          else
            tostring
            | gsub("[\u001f\t\r\n]"; " ")
          end;

        first(.[] | select(.id == $event_id))
        | [
            (.startDate | epoch | tostring),
            (.endDate | epoch | tostring),
            (.isAllDay | tostring),
            (.title // "(untitled)" | clean),
            (.calendar.title // "" | clean),
            (.calendar.color // ""),
            (.location // "" | clean),
            (.organizer.name // "" | clean),
            (.organizer.email // "" | clean),
            (.recurrence.description // "" | clean),
            (.status // "" | clean),
            (.availability // "" | clean),
            (.meetingUrl // "" | clean),
            (
              [
                (.attendees // [])[]
                | select(.status == "accepted")
              ]
              | length
              | tostring
            ),
            (
              [
                (.attendees // [])[]
                | select(.status == "tentative")
              ]
              | length
              | tostring
            ),
            (
              [
                (.attendees // [])[]
                | select(.status == "declined")
              ]
              | length
              | tostring
            ),
            (
              [
                (.attendees // [])[]
                | select(
                    .status != "accepted"
                    and .status != "tentative"
                    and .status != "declined"
                  )
              ]
              | length
              | tostring
            ),
            (
              (.attendees // [])
              | length
              | tostring
            )
          ]
        | join("\u001f")
      ' "$events_file"
  )

  local start_epoch
  local end_epoch
  local is_all_day
  local title
  local calendar
  local calendar_color
  local location
  local organizer_name
  local organizer_email
  local recurrence
  local status
  local availability
  local meeting_url
  local accepted_count
  local tentative_count
  local declined_count
  local pending_count
  local attendee_count

  IFS=$'\x1f' read -r \
    start_epoch \
    end_epoch \
    is_all_day \
    title \
    calendar \
    calendar_color \
    location \
    organizer_name \
    organizer_email \
    recurrence \
    status \
    availability \
    meeting_url \
    accepted_count \
    tentative_count \
    declined_count \
    pending_count \
    attendee_count <<<"$fields"

  if [ "$is_all_day" = "true" ]; then
    when="$(
      date -r "$start_epoch" '+%A, %d %B'
    ) · All day"
  else
    when="$(
      date -r "$start_epoch" '+%A, %d %B'
    ) · $(
      date -r "$start_epoch" '+%H:%M'
    )–$(
      date -r "$end_epoch" '+%H:%M'
    )"
  fi

  printf '\033[1m%s\033[0m\n\n' "$title"

  printf '%-13s %s\n' \
    "When" \
    "$when"

  printf '%-13s %s\n' \
    "Calendar" \
    "$(colorize_calendar "$calendar" "$calendar_color")"

  if [ -n "$location" ]; then
    printf '%-13s %s\n' \
      "Location" \
      "$location"
  fi

  if [ -n "$organizer_name" ] || [ -n "$organizer_email" ]; then
    local organizer

    if [ -n "$organizer_name" ] && [ -n "$organizer_email" ]; then
      organizer="$organizer_name <$organizer_email>"
    else
      organizer="${organizer_name:-$organizer_email}"
    fi

    printf '%-13s %s\n' \
      "Organizer" \
      "$organizer"
  fi

  if [ -n "$recurrence" ]; then
    printf '%-13s %s\n' \
      "Repeats" \
      "$recurrence"
  fi

  if [ -n "$status" ]; then
    printf '%-13s %s\n' \
      "Status" \
      "$status"
  fi

  if [ -n "$availability" ]; then
    printf '%-13s %s\n' \
      "Availability" \
      "$availability"
  fi

  if [ "$attendee_count" -gt 0 ]; then
    printf '%-13s %s/%s accepted' \
      "Participants" \
      "$accepted_count" \
      "$attendee_count"

    if [ "$tentative_count" -gt 0 ]; then
      printf ' · %s tentative' \
        "$tentative_count"
    fi

    if [ "$declined_count" -gt 0 ]; then
      printf ' · %s declined' \
        "$declined_count"
    fi

    if [ "$pending_count" -gt 0 ]; then
      printf ' · %s pending' \
        "$pending_count"
    fi

    printf '\n\n\033[1mAttendees\033[0m\n'

    "$JQ" -r \
      --arg event_id "$event_id" '
        first(.[] | select(.id == $event_id))
        | (.attendees // [])
        | sort_by([
            (
              if .status == "accepted" then 0
              elif .status == "tentative" then 1
              elif .status == "declined" then 2
              else 3
              end
            ),
            (.name // .email // "")
          ])
        | .[]
        | [
            (.status // "unknown"),
            (
              .name // ""
              | gsub("[\u001f\t\r\n]"; " ")
            ),
            (
              .email // ""
              | gsub("[\u001f\t\r\n]"; " ")
            ),
            (
              (.isCurrentUser // false)
              | tostring
            )
          ]
        | join("\u001f")
      ' "$events_file" |
      while IFS=$'\x1f' read -r \
        attendee_status \
        attendee_name \
        attendee_email \
        is_current_user; do

        case "$attendee_status" in
        accepted)
          attendee_icon=$'\033[32m✓\033[0m'
          ;;
        tentative)
          attendee_icon=$'\033[33m?\033[0m'
          ;;
        declined)
          attendee_icon=$'\033[31m✗\033[0m'
          ;;
        *)
          attendee_icon=$'\033[2m•\033[0m'
          ;;
        esac

        local attendee

        if [ -n "$attendee_name" ] && [ -n "$attendee_email" ]; then
          attendee="$attendee_name <$attendee_email>"
        else
          attendee="${attendee_name:-$attendee_email}"
        fi

        if [ "$is_current_user" = "true" ]; then
          attendee="$attendee (you)"
        fi

        printf '  %b %s\n' \
          "$attendee_icon" \
          "$attendee"
      done
  fi

  notes=$(
    "$JQ" -r \
      --arg event_id "$event_id" '
        first(
          .[]
          | select(.id == $event_id)
          | .notes
        ) // empty
      ' "$events_file"
  )

  if [ -n "$notes" ]; then
    printf '\n\033[1mNotes\033[0m\n%s\n' \
      "$notes"
  fi

  if [ -n "$meeting_url" ]; then
    printf '\n%-13s %s\n' \
      "Meeting" \
      "$meeting_url"
  fi
}
