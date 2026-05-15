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

# git add . / -A: check for .env in working tree.
# Use anchored regex so `git add .env.example` (single file) is NOT mistaken
# for `git add .` (everything). Bash glob treats `.` as a literal char that
# matches itself, which caused the previous version to false-positive on
# every single-file stage of a name starting with a dot.
if [[ "$CMD" =~ (^|[[:space:]])"git add ."([[:space:]]|$) ]] || \
   [[ "$CMD" =~ (^|[[:space:]])"git add -A"([[:space:]]|$) ]] || \
   [[ "$CMD" =~ (^|[[:space:]])"git add --all"([[:space:]]|$) ]]; then
  ENV=$(git status --porcelain 2>/dev/null | grep -E '^[ AM?]+\.env$|^[ AM?]+\.env\.(local|production|development|test)$' || true)
  [[ -n "$ENV" ]] && echo "BLOCKED: git add . would stage real .env files" && exit 2
fi

# On commit: check staged .env files
if [[ "$CMD" == *"git commit"* ]]; then
  ENVSTAGED=$(git diff --cached --name-only 2>/dev/null | grep -E '\.env$|\.env\.local$|\.env\.production$|\.env\.development$' || true)
  [[ -n "$ENVSTAGED" ]] && echo "BLOCKED: .env staged for commit" && exit 2

  # Scan for secret patterns. Pattern fragments are concatenated at runtime
  # so this file itself does NOT contain a literal `BEGIN.PRIVATE.KEY`
  # match — earlier versions self-matched during propagation commits because
  # the regex `BEGIN.PRIVATE.KEY` (with `.` as wildcard) matched its own
  # source-text occurrence in the diff.
  PAT_AWS='AKIA[A-Z0-9]{16}'
  PAT_OPENAI='sk-[a-zA-Z0-9]{48}'
  PAT_GH='ghp_[a-zA-Z0-9]{36}'
  PAT_GCP='AIza[a-zA-Z0-9_-]{35}'
  PAT_PEM='-----BEGIN [A-Z ]+KEY-----'
  COMBINED="${PAT_AWS}|${PAT_OPENAI}|${PAT_GH}|${PAT_GCP}|${PAT_PEM}"
  SECRETS=$(git diff --cached -U0 2>/dev/null | grep -iE "$COMBINED" || true)
  [[ -n "$SECRETS" ]] && echo "BLOCKED: secrets detected in staged changes" && exit 2
fi

exit 0
