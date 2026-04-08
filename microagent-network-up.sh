#!/usr/bin/env bash
set -euo pipefail

wait_for_primary_interface() {
  local attempt=0
  while [ "$attempt" -lt 100 ]; do
    local iface
    iface="$(find /sys/class/net -mindepth 1 -maxdepth 1 -printf '%f\n' | grep -v '^lo$' | head -n1 || true)"
    if [ -n "$iface" ]; then
      printf '%s\n' "$iface"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 0.1
  done
  return 1
}

u32_to_ipv4() {
  local value="$1"
  printf '%d.%d.%d.%d' \
    $(((value >> 24) & 255)) \
    $(((value >> 16) & 255)) \
    $(((value >> 8) & 255)) \
    $((value & 255))
}

primary_iface="$(wait_for_primary_interface)"
mac="$(cat "/sys/class/net/${primary_iface}/address")"
IFS=':' read -r mac0 mac1 mac2 mac3 mac4 mac5 <<<"$mac"

guest_u32=$((((16#${mac2}) << 24) | ((16#${mac3}) << 16) | ((16#${mac4}) << 8) | (16#${mac5})))
gateway_u32=$((guest_u32 - 1))

guest_ip="$(u32_to_ipv4 "$guest_u32")"
gateway_ip="$(u32_to_ipv4 "$gateway_u32")"

ip link set dev lo up
ip link set dev "$primary_iface" up
ip addr replace "${guest_ip}/30" dev "$primary_iface"
ip route replace default via "$gateway_ip" dev "$primary_iface"

mkdir -p /etc
cat >/etc/resolv.conf <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
