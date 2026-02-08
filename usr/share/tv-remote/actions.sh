#!/bin/bash
set -x
export DISPLAY=:0
export XAUTHORITY=$(find /run/user/$(id -u)/ -name Xauthority 2>/dev/null | head -n 1)

case "$1" in
    "open_video")
        pkill -u $(id -u) freetube || true
        sleep 0.5
	echo 1 | sudo tee /sys/bus/pci/devices/0000:00:03.0/remove
	echo 1 | sudo tee /sys/bus/pci/rescan
	systemctl --user restart pipewire wireplumber
	resettv
        /snap/bin/freetube --disable-gpu --url "$2" > /dev/null 2>&1 &
        sleep 5
        xdotool key f
        ;;
    "toggle")
        xdotool key space
        ;;
    "volume")
        # This ignores hardware names and targets the system "Sink"
        pactl set-sink-volume @DEFAULT_SINK@ "${2}%"
        ;;
    "rewind")
	xdotool key Left
	;;
    "fast")
	xdotool key Right
	;;
esac
