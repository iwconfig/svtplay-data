#!/bin/bash

# Waits for input from port 15328 and then pipes it to the
# notification daemon. Run this script in the background on the
# receiving LAN computer.

notify() {
    notify-send.sh "SVTPLAY-DATA ERROR!" "$1" -u critical
}

while true; do
    nc -l -p 15328 | while read msg; do notify "$msg"; done
done
