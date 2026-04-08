#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:0

Xvfb "$DISPLAY" -screen 0 1280x800x24 >/tmp/xvfb.log 2>&1 &
XVFB_PID=$!

for _ in $(seq 1 50); do
  if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

runuser -u node -- env DISPLAY="$DISPLAY" openbox >/tmp/openbox.log 2>&1 &
runuser -u node -- env DISPLAY="$DISPLAY" xterm -fa Monospace -fs 12 >/tmp/xterm.log 2>&1 &

x11vnc -display "$DISPLAY" -rfbport 5900 -forever -shared -nopw >/tmp/x11vnc.log 2>&1 &
websockify --web=/usr/share/novnc 6080 localhost:5900 >/tmp/websockify.log 2>&1 &

trap 'kill $XVFB_PID || true; kill 0 || true; exit 0' INT TERM
wait -n
