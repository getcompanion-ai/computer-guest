#!/usr/bin/env bash
set -uo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

log() {
  printf '[microagent-init] %s\n' "$*" >&2
}

read_machine_name() {
  if [ -r /etc/microagent/machine-name ]; then
    tr -d '\r\n' </etc/microagent/machine-name
    return 0
  fi
  if [ -r /etc/hostname ]; then
    tr -d '\r\n' </etc/hostname
    return 0
  fi
  printf 'microagentcomputer'
}

mountpoint -q /proc || mount -t proc proc /proc
mountpoint -q /sys || mount -t sysfs sysfs /sys
mountpoint -q /dev || mount -t devtmpfs devtmpfs /dev
mkdir -p /dev/pts /dev/shm
mountpoint -q /dev/pts || mount -t devpts devpts /dev/pts -o mode=620,ptmxmode=666,gid=5
mountpoint -q /dev/shm || mount -t tmpfs tmpfs /dev/shm
mountpoint -q /run || mount -t tmpfs tmpfs /run

mkdir -p /tmp /var/tmp /run/sshd /var/log
chmod 1777 /tmp /var/tmp

cleanup() {
  trap - INT TERM
  [ -n "${rng_pid:-}" ] && kill "$rng_pid" >/dev/null 2>&1 || true
  [ -n "${sshd_pid:-}" ] && kill "$sshd_pid" >/dev/null 2>&1 || true
  [ -n "${desktop_pid:-}" ] && kill "$desktop_pid" >/dev/null 2>&1 || true
  wait >/dev/null 2>&1 || true
  exit 0
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

start_sshd() {
  reap_if_needed "${sshd_pid:-}"
  log "starting sshd on 2222"
  /usr/sbin/sshd -D -e >>/var/log/sshd.log 2>&1 &
  sshd_pid=$!
}

start_desktop() {
  reap_if_needed "${desktop_pid:-}"
  log "starting noVNC desktop on 6080"
  /usr/local/bin/microagent-desktop-session >>/var/log/desktop.log 2>&1 &
  desktop_pid=$!
}

trap cleanup INT TERM

log "bringing up guest network"
if ! /usr/local/bin/microagent-network-up >/var/log/network.log 2>&1; then
  cat /var/log/network.log >&2 || true
  exit 1
fi

machine_name="$(read_machine_name)"
export COMPUTER_NAME="$machine_name"
printf '%s\n' "$machine_name" >/etc/hostname
cat >/etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 $machine_name
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
hostname "$machine_name" >/dev/null 2>&1 || true

if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
  log "generating ssh host keys"
  ssh-keygen -A
fi

if [ -f /etc/microagent/authorized_keys ]; then
  log "installing injected authorized_keys for node"
  install -d -m 0700 -o node -g node /home/node/.ssh
  install -m 0600 -o node -g node /etc/microagent/authorized_keys /home/node/.ssh/authorized_keys
fi

if [ -f /etc/microagent/trusted_user_ca_keys ]; then
  log "using injected trusted user CA keys"
  chmod 0644 /etc/microagent/trusted_user_ca_keys
fi

if command -v jitterentropy-rngd >/dev/null 2>&1; then
  log "starting jitterentropy-rngd"
  jitterentropy-rngd -v >/var/log/jitterentropy.log 2>&1 &
  rng_pid=$!
fi

start_sshd
start_desktop

while true; do
  if ! pid_running "${sshd_pid:-}"; then
    log "sshd exited; restarting"
    start_sshd
  fi
  if ! pid_running "${desktop_pid:-}"; then
    log "desktop session exited; restarting"
    start_desktop
  fi
  sleep 1
done
