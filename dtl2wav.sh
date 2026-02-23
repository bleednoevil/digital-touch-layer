#!/bin/bash

DTL_FILE="$1"
OUT_WAV="${DTL_FILE%.dtl}.wav"

UP_SOUND="dtl_up.wav"
DOWN_SOUND="dtl_down.wav"

TMP_DIR=$(mktemp -d)
INDEX=0
LAST_TIME=""

if [ -z "$DTL_FILE" ]; then
  echo "Usage: $0 file.dtl"
  exit 1
fi

if [ ! -f "$DTL_FILE" ]; then
  echo "File not found: $DTL_FILE"
  exit 1
fi

echo "Converting $DTL_FILE → $OUT_WAV"

while read -r line; do
  [[ "$line" =~ VOLUME_ ]] || continue

  # Extract timestamp inside brackets [ ]
  TS=$(echo "$line" | grep -o '\[.*\]' | tr -d '[]')

  if [ -z "$TS" ]; then
    continue
  fi

  CUR_TIME=$(date -j -f "%Y-%m-%d %H:%M:%S" "$TS" "+%s" 2>/dev/null)

  if [ -z "$CUR_TIME" ]; then
    continue
  fi

  if [ -n "$LAST_TIME" ]; then
    DELAY=$((CUR_TIME - LAST_TIME))

    if (( DELAY > 0 )); then
      sox -n -r 44100 -c 2 "$TMP_DIR/$(printf "%05d" $INDEX).wav" trim 0 "$DELAY"
      INDEX=$((INDEX + 1))
    fi
  fi

  case "$line" in
    *VOLUME_UP*)
      sox "$UP_SOUND" "$TMP_DIR/$(printf "%05d" $INDEX).wav"
      ;;
    *VOLUME_DOWN*)
      sox "$DOWN_SOUND" "$TMP_DIR/$(printf "%05d" $INDEX).wav"
      ;;
  esac

  LAST_TIME="$CUR_TIME"
  INDEX=$((INDEX + 1))

done < "$DTL_FILE"

files=$(ls "$TMP_DIR"/*.wav 2>/dev/null)

if [ -z "$files" ]; then
  echo "No audio events found."
  rm -rf "$TMP_DIR"
  exit 1
fi

sox $files "$OUT_WAV"

rm -rf "$TMP_DIR"

echo "Done → $OUT_WAV"

