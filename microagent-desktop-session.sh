#!/usr/bin/env bash
set -uo pipefail

export DISPLAY=:0

log() {
  printf '[microagent-desktop] %s\n' "$*" >&2
}

pid_running() {
  local pid="${1:-}"
  [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1
}

reap_if_needed() {
  local pid="${1:-}"
  if [ -n "$pid" ]; then
    wait "$pid" >/dev/null 2>&1 || true
  fi
}

cleanup() {
  trap - INT TERM
  [ -n "${websockify_pid:-}" ] && kill "$websockify_pid" >/dev/null 2>&1 || true
  [ -n "${x11vnc_pid:-}" ] && kill "$x11vnc_pid" >/dev/null 2>&1 || true
  [ -n "${xterm_pid:-}" ] && kill "$xterm_pid" >/dev/null 2>&1 || true
  [ -n "${openbox_pid:-}" ] && kill "$openbox_pid" >/dev/null 2>&1 || true
  [ -n "${xvfb_pid:-}" ] && kill "$xvfb_pid" >/dev/null 2>&1 || true
  wait >/dev/null 2>&1 || true
  exit 0
}

start_openbox() {
  reap_if_needed "${openbox_pid:-}"
  log "starting openbox"
  runuser -u node -- env DISPLAY="$DISPLAY" openbox >>/tmp/openbox.log 2>&1 &
  openbox_pid=$!
}

start_xterm() {
  reap_if_needed "${xterm_pid:-}"
  log "starting xterm"
  runuser -u node -- env DISPLAY="$DISPLAY" xterm -fa Monospace -fs 12 >>/tmp/xterm.log 2>&1 &
  xterm_pid=$!
}

start_x11vnc() {
  reap_if_needed "${x11vnc_pid:-}"
  log "starting x11vnc"
  x11vnc -display "$DISPLAY" -rfbport 5900 -forever -shared -nopw >>/tmp/x11vnc.log 2>&1 &
  x11vnc_pid=$!
}

start_websockify() {
  reap_if_needed "${websockify_pid:-}"
  log "starting websockify on 6080"
  websockify --web=/usr/share/novnc 6080 localhost:5900 >>/tmp/websockify.log 2>&1 &
  websockify_pid=$!
}

trap cleanup INT TERM

log "starting Xvfb"
Xvfb "$DISPLAY" -screen 0 1280x800x24 >/tmp/xvfb.log 2>&1 &
xvfb_pid=$!

ready=0
for _ in $(seq 1 100); do
  if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! pid_running "$xvfb_pid"; then
    log "Xvfb exited before display became ready"
    wait "$xvfb_pid" >/dev/null 2>&1 || true
    exit 1
  fi
  sleep 0.1
done

if [ "$ready" -ne 1 ]; then
  log "Xvfb did not become ready in time"
  exit 1
fi

start_openbox
start_xterm
start_x11vnc
start_websockify

while true; do
  if ! pid_running "$xvfb_pid"; then
    log "Xvfb exited; stopping desktop session"
    wait "$xvfb_pid" >/dev/null 2>&1 || true
    exit 1
  fi
  if ! pid_running "${openbox_pid:-}"; then
    log "openbox exited; restarting"
    start_openbox
  fi
  if ! pid_running "${xterm_pid:-}"; then
    log "xterm exited; restarting"
    start_xterm
  fi
  if ! pid_running "${x11vnc_pid:-}"; then
    log "x11vnc exited; restarting"
    start_x11vnc
  fi
  if ! pid_running "${websockify_pid:-}"; then
    log "websockify exited; restarting"
    start_websockify
  fi
  sleep 1
done
