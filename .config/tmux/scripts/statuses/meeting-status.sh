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

ICAL_GUY=$(find_binary ical-guy) || exit 0
JQ=$(find_binary jq) || exit 0

meetings=$(
  "$ICAL_GUY" meeting list \
    --format json \
    --no-color \
    2>/dev/null
) || exit 0

meeting_state=$(
  printf '%s\n' "$meetings" |
    "$JQ" -r '
      now as $now
      |
      [
        .[]
        | {
            start: (.startDate | fromdateiso8601),
            end: (.endDate | fromdateiso8601)
          }
        | select(.end > $now)
      ]
      | sort_by(.start)
      | first
      |
      if . == null then
        empty
      elif .start <= $now then
        "active"
      else
        ((.start - $now) / 60 | ceil) as $minutes
        |
        if $minutes <= 10 then
          "urgent \($minutes)"
        elif $minutes <= 30 then
          "warning \($minutes)"
        elif $minutes <= 60 then
          "info \($minutes)"
        else
          empty
        end
      end
    ' 2>/dev/null
)

read -r state minutes <<<"$meeting_state"

case "$state" in
info)
  # Meeting within an hour: unobtrusive.
  printf '#[fg=#89b4fa]󰃰 #[default]'
  ;;

warning)
  # Meeting in 10–30 minutes: add useful context.
  printf '#[fg=#f9e2af,bold]󰃰 %sm#[default]' "$minutes"
  ;;

urgent)
  # Meeting in 0–10 minutes: turn it into a badge.
  printf '#[fg=#1e1e2e,bg=#f38ba8,bold] 󰃰 %sm #[default]' "$minutes"
  ;;

active)
  # Meeting is currently happening.
  printf '#[fg=#1e1e2e,bg=#f38ba8,bold] 󰃰 NOW #[default]'
  ;;
esac
