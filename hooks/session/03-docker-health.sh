#!/bin/bash
set +e
# Hook: Docker Health Check
# Event: SessionStart
# Verifies Docker daemon is running and project containers are healthy

# Check Docker daemon
if ! docker info &>/dev/null; then
  echo "WARNING: Docker daemon is not running. Start Docker Desktop first."
  exit 0
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
COMPOSE_FILE="$ROOT/docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
  exit 0
fi

# Check container status
CONTAINERS=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null)

if [ -z "$CONTAINERS" ]; then
  echo "WARNING: No containers running for this project"
  echo "Start with: docker compose up -d --build"
  exit 0
fi

# Parse container health
UNHEALTHY=$(echo "$CONTAINERS" | jq -r 'select(.Health == "unhealthy" or .State != "running") | .Name' 2>/dev/null)

if [ -n "$UNHEALTHY" ]; then
  echo "UNHEALTHY CONTAINERS:"
  echo "$UNHEALTHY"
  echo "Rebuild with: docker compose down && docker compose up -d --build"
else
  RUNNING=$(echo "$CONTAINERS" | jq -r '.Name' 2>/dev/null | wc -l | tr -d ' ')
  echo "Docker: $RUNNING container(s) running and healthy"
fi

exit 0
