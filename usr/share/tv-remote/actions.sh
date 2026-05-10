#!/bin/bash

# --- Configuration ---
set -x
TARGET_USER="tards"
USER_ID=1000
export DISPLAY=:0

# 1. Force the script to run as user 'n' if started as root
# This aligns D-Bus and PulseAudio permissions immediately.
if [ "$(id -u)" -eq 0 ]; then
    exec sudo -u "$TARGET_USER" "$0" "$@"
fi

# 2. Environment Setup (Now running as user 'n')
export XAUTHORITY=$(ls /run/user/$USER_ID/.mutter-Xwaylandauth.* | head -n 1)
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"
export XDG_RUNTIME_DIR="/run/user/$USER_ID"
export PULSE_RUNTIME_PATH="/run/user/$USER_ID/pulse"
export NO_AT_BRIDGE=1
audio

LOCKFILE="/tmp/freetube_launch.lock"

case "$1" in
    "open_video" | "alt")
       if [ -f "$LOCKFILE" ]; then exit 0; fi
       touch "$LOCKFILE"
       pkill -u tards freetube || true
       sleep 1

       # Launch FreeTube
       /usr/bin/freetube --no-sandbox "$2" > /dev/null 2>&1 &
       
       # Wait up to 15 seconds for the window to appear
       for i in {1..15}; do
           WID=$(xdotool search --onlyvisible --name "FreeTube" | head -n 1)
           if [ -n "$WID" ]; then
               xdotool windowactivate --sync "$WID"
               sleep 1
               xdotool key f
               break
           fi
           sleep 1
       done
       rm -f "$LOCKFILE"
       ;;

    "toggle")
        xdotool key space
        ;;

    "volume")
        # Global system volume adjustment
        pactl set-sink-volume @DEFAULT_SINK@ "${2}%"
        ;;

    "rewind")
        xdotool key Left
        ;;

    "fast")
        xdotool key Right
        ;;

    "full")
        xdotool key f
        ;;
esac
