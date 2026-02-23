#!/bin/bash

# ------------------------------
# Digital Touch Layer: Volume Logger + Audio Feedback
# ------------------------------

DTL_DIR="/Users/your_macos_username/"
SOUND_DIR="$DTL_DIR/"

DTL_UP_SOUND="$SOUND_DIR/dtl_up.wav"
DTL_DOWN_SOUND="$SOUND_DIR/dtl_down.wav"

mkdir -p "$DTL_DIR"
mkdir -p "$SOUND_DIR"

DTL_FILE="$DTL_DIR/touch_$(date +%Y%m%d_%H%M%S).dtl"

echo "# Digital Touch Layer: DTL Session Started $(date)" | tee -a "$DTL_FILE"
echo "# Ctrl+C to exit" | tee -a "$DTL_FILE"
echo "----------------------------------------" | tee -a "$DTL_FILE"

cleanup() {
    echo "----------------------------------------" | tee -a "$DTL_FILE"
    echo "# Session terminated $(date)" | tee -a "$DTL_FILE"
    exit 0
}
trap cleanup SIGINT

# ------------------------------
# State
# ------------------------------

last_volume=""

# ------------------------------
# Volume Watcher Loop
# ------------------------------

while true; do
    vol=$(osascript -e "output volume of (get volume settings)" 
2>/dev/null)
    ts=$(date '+%Y-%m-%d %H:%M:%S')

    # Initialize baseline (prevents first-run false trigger)
    if [[ -z "$last_volume" ]]; then
        last_volume="$vol"
        sleep 0.25
        continue
    fi

    if [[ "$vol" != "$last_volume" ]]; then
        if (( vol > last_volume )); then
            echo "[$ts] VOLUME_UP level=$vol" | tee -a "$DTL_FILE"
            [[ -f "$DTL_UP_SOUND" ]] && afplay "$DTL_UP_SOUND" &
        elif (( vol < last_volume )); then
            echo "[$ts] VOLUME_DOWN level=$vol" | tee -a "$DTL_FILE"
            [[ -f "$DTL_DOWN_SOUND" ]] && afplay "$DTL_DOWN_SOUND" &
        fi

        last_volume="$vol"
    fi

    sleep 0.25   # 4x per second, stable, no jitter
done

