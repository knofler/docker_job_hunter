#!/bin/bash
set +e
# Hook: No Local npm Guard
# Event: PreToolUse (Bash)
# Blocks bare npm/npx/node commands — must use docker compose exec
# macOS-compatible (no grep -P)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Allow docker compose exec commands (the correct way)
if echo "$COMMAND" | grep -qE 'docker\s+compose\s+exec'; then
  exit 0
fi

# Allow docker exec commands
if echo "$COMMAND" | grep -qE 'docker\s+exec'; then
  exit 0
fi

# Allow npm/node version checks
if echo "$COMMAND" | grep -qE '(npm|node|npx)\s+(-v|--version|version)'; then
  exit 0
fi

# Allow if explicitly in a CI context
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
  exit 0
fi

# Block bare npm install/ci/run/start/build/test/lint (POSIX-compatible regex)
if echo "$COMMAND" | grep -qE '^[[:space:]]*(npm\s+(install|ci|run|start|build|test|lint))'; then
  echo "BLOCKED: Direct npm commands are not allowed on the host."
  echo "Use Docker instead:"
  echo "  docker compose exec app npm install"
  echo "  docker compose exec app npm run build"
  exit 2
fi

# Block bare npx (unless it's inside a docker command — already allowed above)
if echo "$COMMAND" | grep -qE '^[[:space:]]*npx\s+'; then
  echo "BLOCKED: Direct npx commands are not allowed on the host."
  echo "Use Docker instead:"
  echo "  docker compose exec app npx tsc --noEmit"
  exit 2
fi

exit 0
