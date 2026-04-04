#!/bin/bash
set +e
# Hook: Block Push to Main — prevents direct push, allows state commits

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only care about git push
[[ "$CMD" != *"git push"* ]] && exit 0

# Check if pushing to main/master
IS_MAIN=false
[[ "$CMD" == *"origin main"* ]] && IS_MAIN=true
[[ "$CMD" == *"origin master"* ]] && IS_MAIN=true
[[ "$CMD" == *":main"* ]] && IS_MAIN=true
[[ "$CMD" == *":master"* ]] && IS_MAIN=true

[[ "$IS_MAIN" == false ]] && exit 0

# Allow gh pr commands
[[ "$CMD" == *"gh pr"* ]] && exit 0

# Allow state update commits
LAST_MSG=$(git log -1 --format=%s 2>/dev/null || true)
[[ "$LAST_MSG" == "chore: update state"* ]] && exit 0

echo "BLOCKED: Direct push to main/master is not allowed."
echo "Push to 'test' first, then create a PR."
exit 2
