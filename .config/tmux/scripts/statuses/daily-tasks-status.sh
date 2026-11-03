#!/usr/bin/env bash

set -u

DAILY_NOTE_PATH="$HOME/.config/nvim/scripts/daily-note-path"

[ -x "$DAILY_NOTE_PATH" ] || exit 0

note=$("$DAILY_NOTE_PATH" 2>/dev/null) || exit 0

# No daily note yet: don't display anything.
[ -r "$note" ] || exit 0

counts=$(
  awk '
    /^##[[:space:]]+/ {
      in_tomorrow = ($0 ~ /^##[[:space:]]+Tomorrow[[:space:]]*$/)
      in_hobby = ($0 ~ /^##[[:space:]]+Hobby[[:space:]]*$/)
    }

    !in_tomorrow && !in_hobby &&
    /^[[:space:]]*[-*+][[:space:]]+\[[ xX]\]/ {
      total++

      if ($0 ~ /^[[:space:]]*[-*+][[:space:]]+\[[xX]\]/) {
        done++
      }
    }

    END {
      print done + 0, total + 0
    }
  ' "$note"
)

read -r done total <<<"$counts"

# No tasks today: don't occupy status-bar space.
((total == 0)) && exit 0

if ((done == total)); then
  # Everything finished.
  printf '#[fg=#a6e3a1,bold]󰄬 %d/%d#[default]' "$done" "$total"
elif ((done > 0)); then
  # Day in progress.
  printf '#[fg=#89b4fa]󰄬 %d/%d#[default]' "$done" "$total"
else
  # Nothing completed yet.
  printf '#[fg=#9399b2]󰄬 %d/%d#[default]' "$done" "$total"
fi
