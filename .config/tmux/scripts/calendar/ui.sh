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
      --expect=enter,ctrl-o \
      --bind="load:pos($default_position)" \
      --header='Enter: details  •  Ctrl-o: open meeting  •  󰍉 has meeting link  •  Esc: close' \
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
        --expect=enter,ctrl-o \
        --bind='j:preview-down' \
        --bind='k:preview-up' \
        --bind='ctrl-d:preview-half-page-down' \
        --bind='ctrl-u:preview-half-page-up' \
        --bind='g:preview-top' \
        --bind='G:preview-bottom' \
        --preview="cat -- '$details_file'" \
        --preview-window='up,90%,wrap,border-none' \
        --header='j/k: scroll  •  C-d/C-u: half page  •  g/G: top/bottom  •  Enter/Esc: back  •  Ctrl-o: open' \
        --header-first
  ); then
    rm -f "$details_file"
    return 1
  fi

  rm -f "$details_file"

  key=${result%%$'\n'*}

  printf '%s\n' "${key:-enter}"
}
