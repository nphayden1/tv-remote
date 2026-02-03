#!/bin/bash
set -x
export DISPLAY=:0
export XAUTHORITY=$(find /run/user/$(id -u)/ -name Xauthority 2>/dev/null | head -n 1)

case "$1" in
    "open_video")
        pkill -u $(id -u) freetube || true
        sleep 0.5
        /snap/bin/freetube --disable-gpu --url "$2" > /dev/null 2>&1 &
        sleep 5
        xdotool key f
        ;;
    "toggle")
        xdotool key space
        ;;
esac
