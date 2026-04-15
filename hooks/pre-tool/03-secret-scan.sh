#!/bin/bash
# Hook: Secret Scanner — blocks commits with secrets/API keys/.env files
set +e

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only care about git add and git commit
[[ "$CMD" != *"git add"* && "$CMD" != *"git commit"* ]] && exit 0

# Block staging .env files explicitly (allow .env.example)
[[ "$CMD" == *"git add"*".env"* && "$CMD" != *".env.example"* ]] && echo "BLOCKED: .env files must not be staged" && exit 2

# Block staging credentials
[[ "$CMD" == *"git add"*".pem"* ]] && echo "BLOCKED: .pem files must not be staged" && exit 2
[[ "$CMD" == *"git add"*".key"* ]] && echo "BLOCKED: .key files must not be staged" && exit 2

# git add . / -A: check for .env in working tree
if [[ "$CMD" == *"git add ."* || "$CMD" == *"git add -A"* ]]; then
  ENV=$(git status --porcelain 2>/dev/null | grep '\.env' || true)
  [[ -n "$ENV" ]] && echo "BLOCKED: git add . would stage .env files" && exit 2
fi

# On commit: check staged .env files
if [[ "$CMD" == *"git commit"* ]]; then
  ENVSTAGED=$(git diff --cached --name-only 2>/dev/null | grep -E '\.env$|\.env\.local$|\.env\.production$|\.env\.development$' || true)
  [[ -n "$ENVSTAGED" ]] && echo "BLOCKED: .env staged for commit" && exit 2

  # Scan for secret patterns
  SECRETS=$(git diff --cached -U0 2>/dev/null | grep -iE 'AKIA[A-Z0-9]{16}|sk-[a-zA-Z0-9]{48}|ghp_[a-zA-Z0-9]{36}|AIza[a-zA-Z0-9_-]{35}|BEGIN.PRIVATE.KEY' || true)
  [[ -n "$SECRETS" ]] && echo "BLOCKED: secrets detected in staged changes" && exit 2
fi

exit 0
