#!/bin/bash

# --- Configuration ---
TARGET_USER="n"
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
    "open_video")
        # Prevent overlapping launch attempts
        if [ -f "$LOCKFILE" ]; then exit 0; fi
        touch "$LOCKFILE"

        # Kill existing instances to start fresh
        pkill -u $USER_ID freetube || true
        sleep 1
        
        # Launch FreeTube with audio and stability flags
        # Removed --disable-dbus to allow it to find PulseAudio
        /usr/bin/freetube --no-sandbox \
            --disable-gpu \
            --disable-software-rasterizer \
            --disable-gpu-compositing \
            --disable-features=WebBluetooth,WebUSB,Vulkan,HardwareMediaKeyHandling \
            --disable-speech-api \
            --ozone-platform=x11 \
            "$2" > /dev/null 2>&1 &
        
        # Wait for the window to draw (HP ProDesk can be slow)
        sleep 10
        
        # Force Fullscreen
        WID=$(xdotool search --name "FreeTube" | head -n 1)
        if [ -n "$WID" ]; then
            xdotool windowactivate --sync "$WID" key f
        else
            xdotool key f
        fi
        
        # Ensure the stream isn't muted (Fixes the silent audio)
        sleep 2
        pactl list sink-inputs | grep Index | cut -d# -f2 | xargs -I{} pactl set-sink-input-mute {} false
        pactl list sink-inputs | grep Index | cut -d# -f2 | xargs -I{} pactl set-sink-input-volume {} 100%
        
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
