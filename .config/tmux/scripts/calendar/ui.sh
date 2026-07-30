#!/usr/bin/env bash

select_event() {
  local event_rows_file=$1
  local default_position=${2:-1}
  local result
  local key
  local selected_row
  local event_id

  result=$(
    "$FZF" \
      --ansi \
      --no-sort \
      --delimiter=$'\t' \
      --with-nth=1 \
      --layout=reverse \
      --border=rounded \
      --info=inline-right \
      --prompt='Calendar › ' \
      --pointer='›' \
      --no-multi \
      --expect=enter,ctrl-o,ctrl-x \
      --bind="load:pos($default_position)" \
      --header='Enter: details  •  Ctrl-o: open meeting  •  Ctrl-x: decline  •  󰍉 has meeting link  •  Esc: close' \
      --header-first \
      <"$event_rows_file"
  ) || return 1

  key=${result%%$'\n'*}
  selected_row=${result#*$'\n'}
  event_id=${selected_row##*$'\t'}

  [ -n "$event_id" ] || return 1

  printf '%s\t%s\n' \
    "${key:-enter}" \
    "$event_id"
}

find_event_row_position() {
  local event_rows_file=$1
  local event_id=$2

  awk -v event_id="$event_id" '
    BEGIN {
      FS = "\t"
    }

    $NF == event_id {
      print NR
      found = 1
      exit
    }

    END {
      if (!found) {
        print 1
      }
    }
  ' "$event_rows_file"
}

show_event_details() {
  local events_file=$1
  local event_id=$2
  local details_file
  local result
  local key

  details_file=$(mktemp)

  build_event_details \
    "$events_file" \
    "$event_id" \
    >"$details_file"

  if ! result=$(
    printf ' \n' |
      "$FZF" \
        --ansi \
        --disabled \
        --no-sort \
        --layout=reverse \
        --border=rounded \
        --no-info \
        --no-multi \
        --prompt='' \
        --pointer='' \
        --expect=enter,ctrl-o,ctrl-x \
        --bind='j:preview-down' \
        --bind='k:preview-up' \
        --bind='ctrl-d:preview-half-page-down' \
        --bind='ctrl-u:preview-half-page-up' \
        --bind='g:preview-top' \
        --bind='G:preview-bottom' \
        --preview="cat -- '$details_file'" \
        --preview-window='up,90%,wrap,border-none' \
        --header='j/k: scroll  •  C-d/C-u: half page  •  g/G: top/bottom  •  Enter/Esc: back  •  Ctrl-o: open  •  Ctrl-x: decline' \
        --header-first
  ); then
    rm -f "$details_file"
    return 1
  fi

  rm -f "$details_file"

  key=${result%%$'\n'*}

  printf '%s\n' "${key:-enter}"
}

confirm_decline_event() {
  local events_file=$1
  local event_id=$2
  local title
  local header
  local answer

  title=$(
    get_event_title \
      "$events_file" \
      "$event_id"
  )

  title=${title//$'\r'/ }
  title=${title//$'\n'/ }

  printf -v header \
    'Decline "%s"?' \
    "$title"

  answer=$(
    printf '%s\n' \
      "Cancel" \
      "Decline meeting" |
      "$FZF" \
        --no-sort \
        --layout=reverse \
        --border=rounded \
        --no-info \
        --prompt='Confirm › ' \
        --pointer='›' \
        --no-multi \
        --bind='load:pos(1)' \
        --header="$header" \
        --header-first
  ) || return 1

  [ "$answer" = "Decline meeting" ]
}
