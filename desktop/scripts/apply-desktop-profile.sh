#!/usr/bin/env bash
set -euo pipefail

: "${HOME:=/home/node}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

PROFILE_VERSION="v1"
PROFILE_ROOT="/opt/desktop"
MARKER_DIR="$XDG_STATE_HOME/microagent/desktop"
MARKER_FILE="$MARKER_DIR/desktop-${PROFILE_VERSION}.seeded"

if [ -f "$MARKER_FILE" ]; then
  exit 0
fi

mkdir -p "$MARKER_DIR" "$XDG_CONFIG_HOME"

# XFCE config
rm -rf "$XDG_CONFIG_HOME/xfce4"
cp -R "$PROFILE_ROOT/xfce" "$XDG_CONFIG_HOME/xfce4"

# Plank config
mkdir -p "$XDG_CONFIG_HOME/plank"
cp -R "$PROFILE_ROOT/plank/." "$XDG_CONFIG_HOME/plank/"

touch "$MARKER_FILE"
echo "Applied desktop profile: ${PROFILE_VERSION}"
