#!/bin/bash
set +e
# Hook: Write host identity for Docker + Telegram host control
# Event: SessionStart
# 1. Writes HOST_HOSTNAME to /tmp for docker-compose (not Dropbox-synced)
# 2. Writes hostname to state/.telegram-active-host (Dropbox-synced)
#    This tells ALL gateways which machine should own Telegram polling.
#    The other machine's gateway reads this file every 10s and deactivates.

HOSTNAME_SHORT=$(hostname -s)

# Docker Compose env (local only, not synced)
echo "HOST_HOSTNAME=$HOSTNAME_SHORT" > /tmp/.myai-host-env

# Telegram host control (synced via Dropbox to all machines)
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STATE_DIR="$ROOT/state"
[ -d "$STATE_DIR" ] || STATE_DIR="$ROOT/AI/state"
if [ -d "$STATE_DIR" ]; then
  echo "$HOSTNAME_SHORT" > "$STATE_DIR/.telegram-active-host"
fi
