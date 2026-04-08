#!/usr/bin/env bash
set -euo pipefail

mountpoint -q /proc || mount -t proc proc /proc
mountpoint -q /sys || mount -t sysfs sysfs /sys
mountpoint -q /dev || mount -t devtmpfs devtmpfs /dev
mountpoint -q /run || mount -t tmpfs tmpfs /run

mkdir -p /tmp /var/tmp /run/sshd /var/log
chmod 1777 /tmp /var/tmp

# PID 1 is the guest supervisor: it brings up the minimum runtime surface and
# stays alive to keep the VM services attached to a single lifecycle root.
if ! /usr/local/bin/microagent-network-up >/var/log/network.log 2>&1; then
  cat /var/log/network.log >&2 || true
  exit 1
fi

if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
  ssh-keygen -A
fi

if [ -f /etc/microagent/authorized_keys ]; then
  install -d -m 0700 -o node -g node /home/node/.ssh
  install -m 0600 -o node -g node /etc/microagent/authorized_keys /home/node/.ssh/authorized_keys
fi

if command -v jitterentropy-rngd >/dev/null 2>&1; then
  jitterentropy-rngd -v >/var/log/jitterentropy.log 2>&1 &
fi

/usr/sbin/sshd -D -e >/var/log/sshd.log 2>&1 &
/usr/local/bin/microagent-desktop-session >/var/log/desktop.log 2>&1 &

trap 'kill 0 || true; exit 0' INT TERM
wait -n
status=$?
kill 0 || true
wait || true
exit "$status"
