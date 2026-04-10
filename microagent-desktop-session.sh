#!/usr/bin/env bash
set -uo pipefail

export DISPLAY=:0
export DESKTOP_SESSION=xfce
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/home/node/.config}"

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
  [ -n "${plank_pid:-}" ] && kill "$plank_pid" >/dev/null 2>&1 || true
  [ -n "${autocutsel_clip_pid:-}" ] && kill "$autocutsel_clip_pid" >/dev/null 2>&1 || true
  [ -n "${autocutsel_pri_pid:-}" ] && kill "$autocutsel_pri_pid" >/dev/null 2>&1 || true
  [ -n "${xfce_pid:-}" ] && kill "$xfce_pid" >/dev/null 2>&1 || true
  [ -n "${dbus_pid:-}" ] && kill "$dbus_pid" >/dev/null 2>&1 || true
  [ -n "${xvfb_pid:-}" ] && kill "$xvfb_pid" >/dev/null 2>&1 || true
  wait >/dev/null 2>&1 || true
  exit 0
}

# Start a persistent D-Bus session and export its address so all child
# processes (XFCE, Plank, autocutsel) share the same bus.
start_dbus() {
  log "starting dbus session"
  eval "$(dbus-launch --sh-syntax)"
  export DBUS_SESSION_BUS_ADDRESS
  dbus_pid="$DBUS_SESSION_BUS_PID"
}

start_xfce() {
  reap_if_needed "${xfce_pid:-}"
  log "starting xfce4-session"
  runuser -u node -- env \
    DISPLAY="$DISPLAY" \
    DESKTOP_SESSION="$DESKTOP_SESSION" \
    XDG_CURRENT_DESKTOP="$XDG_CURRENT_DESKTOP" \
    XDG_SESSION_DESKTOP="$XDG_SESSION_DESKTOP" \
    XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
    DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
    xfce4-session >>/tmp/xfce.log 2>&1 &
  xfce_pid=$!
}

wait_for_wm() {
  local i
  for i in $(seq 1 50); do
    if xprop -root -display "$DISPLAY" _NET_SUPPORTING_WM_CHECK >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  log "warning: window manager did not appear within 5s"
  return 1
}

start_plank() {
  reap_if_needed "${plank_pid:-}"
  log "starting plank"
  runuser -u node -- env \
    DISPLAY="$DISPLAY" \
    XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
    DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
    plank >>/tmp/plank.log 2>&1 &
  plank_pid=$!
}

start_clipboard() {
  if ! command -v autocutsel >/dev/null 2>&1; then
    return
  fi
  reap_if_needed "${autocutsel_clip_pid:-}"
  reap_if_needed "${autocutsel_pri_pid:-}"
  log "starting clipboard sync"
  runuser -u node -- env DISPLAY="$DISPLAY" autocutsel -selection CLIPBOARD -fork >>/tmp/autocutsel.log 2>&1
  autocutsel_clip_pid=$(pgrep -n -u node autocutsel)
  runuser -u node -- env DISPLAY="$DISPLAY" autocutsel -selection PRIMARY -fork >>/tmp/autocutsel.log 2>&1
  autocutsel_pri_pid=$(pgrep -n -u node -f 'autocutsel.*PRIMARY')
}

start_x11vnc() {
  reap_if_needed "${x11vnc_pid:-}"
  log "starting x11vnc"
  x11vnc -display "$DISPLAY" -rfbport 5900 -forever -shared -nopw -quiet >>/tmp/x11vnc.log 2>&1 &
  x11vnc_pid=$!
}

start_websockify() {
  reap_if_needed "${websockify_pid:-}"
  log "starting websockify on 6080"
  websockify --web=/usr/share/novnc 6080 localhost:5900 >>/tmp/websockify.log 2>&1 &
  websockify_pid=$!
}

# Restart the full desktop session (XFCE + Plank + clipboard) on the same
# D-Bus so all components share one session bus.
restart_desktop_session() {
  [ -n "${plank_pid:-}" ] && kill "$plank_pid" >/dev/null 2>&1 || true
  [ -n "${autocutsel_clip_pid:-}" ] && kill "$autocutsel_clip_pid" >/dev/null 2>&1 || true
  [ -n "${autocutsel_pri_pid:-}" ] && kill "$autocutsel_pri_pid" >/dev/null 2>&1 || true
  start_xfce
  wait_for_wm || true
  start_plank
  start_clipboard
}

trap cleanup INT TERM

# Apply desktop profile on first boot
log "applying desktop profile"
runuser -u node -- /opt/desktop/scripts/apply-desktop-profile.sh 2>&1 || true

# Start Xvfb
log "starting Xvfb"
Xvfb "$DISPLAY" -screen 0 1280x800x24 -ac >/tmp/xvfb.log 2>&1 &
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

# Disable screensaver/DPMS
xset -display "$DISPLAY" -dpms s off s noblank >/dev/null 2>&1 || true

# Start persistent D-Bus session shared by all desktop components
start_dbus

# Start desktop stack
start_xfce
wait_for_wm || true
start_plank
start_clipboard
start_x11vnc
start_websockify

# Monitor and restart dead processes
while true; do
  if ! pid_running "$xvfb_pid"; then
    log "Xvfb exited; stopping desktop session"
    wait "$xvfb_pid" >/dev/null 2>&1 || true
    exit 1
  fi
  if ! pid_running "${xfce_pid:-}"; then
    log "xfce4-session exited; restarting desktop session"
    restart_desktop_session
  fi
  if ! pid_running "${plank_pid:-}"; then
    log "plank exited; restarting"
    start_plank
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
