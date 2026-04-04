# Multi-Machine Workflow (Dropbox Sync)

> The developer works across multiple machines (e.g. PH11911 at work, MacBook Pro at home) with the codebase synced via Dropbox. This creates specific challenges that every AI agent and the developer must handle on session start.

---

## The Problem

1. **Stale Docker containers**: Code syncs via Dropbox but Docker containers on the other machine still run the old build. The app serves outdated code until containers are rebuilt.
2. **Dropbox conflict files**: When both machines edit the same file (or Dropbox syncs mid-write), Dropbox creates `(Machine's conflicted copy YYYY-MM-DD)` duplicates. These pollute the repo.
3. **Git state divergence**: The `.git` directory syncs via Dropbox, which can cause lock files, stale refs, or index corruption.
4. **node_modules / .next cache**: These directories may contain platform-specific binaries (darwin vs linux) that break when synced.

---

## Mandatory: Session Start Checklist (Every Machine Switch)

Run these steps **every time** you start work on a different machine from where the last session ended. AI agents must execute this automatically on `session start` or `agent mode`.

### Step 1: Wait for Dropbox Sync

```bash
# Check Dropbox sync status (macOS)
dropbox status 2>/dev/null || echo "Check Dropbox icon in menu bar — wait for 'Up to date'"
```

**Do NOT start work until Dropbox shows "Up to date".** Starting with a partial sync will create conflicts.

### Step 2: Clean Dropbox Conflict Files

```bash
# Find and count conflicts
find . -name "*conflicted*" -o -name "* (1)*" -o -name "* (2)*" 2>/dev/null | wc -l

# Review them (always review before deleting)
find . -name "*conflicted*" -o -name "* (1)*" -o -name "* (2)*" 2>/dev/null

# Delete all (safe — originals are always the non-suffixed files)
find . -name "*conflicted*" -delete 2>/dev/null
```

### Step 3: Fix Git State

```bash
# Remove stale lock files
rm -f .git/index.lock .git/refs/heads/*.lock 2>/dev/null

# Verify git is healthy
git status
git log --oneline -3
```

If `git status` shows unexpected changes or errors, run:
```bash
git checkout -- .  # Only if you're sure all changes were committed last session
```

### Step 4: Rebuild Docker Containers

**This is the critical step.** The Docker container has cached the old code. You must rebuild.

```bash
# For any project with Docker Compose
docker compose down
docker compose up -d --build

# Wait for healthy status
docker compose ps  # Should show "healthy"

# Verify the app is running with latest code
docker compose logs app --tail 20
```

**Why `--build` is required**: Docker Compose volumes mount the source code, but:
- `node_modules` inside the container may be stale (missing new packages)
- `.next` cache may reference deleted/renamed files
- The entrypoint script pre-compiles routes on startup — stale cache = stale routes

If you only need to refresh the code (no new packages), a restart may suffice:
```bash
docker compose restart app
# Then verify the app compiled the latest files:
docker compose logs app --tail 30
```

### Step 5: Verify Build

```bash
# Type check
docker compose exec app npx tsc --noEmit --pretty

# Quick health check
curl -s http://localhost:3400/api/health | jq .
```

### Step 6: Pull Latest Git State

```bash
git fetch origin
git log --oneline origin/main..HEAD   # Check if local is ahead
git log --oneline HEAD..origin/main   # Check if remote is ahead
```

If remote is ahead (changes pushed from the other machine):
```bash
git pull origin main
```

---

## When to Full Rebuild vs Restart

| Scenario | Action |
|----------|--------|
| Only code changes (same packages) | `docker compose restart app` |
| New npm packages added | `docker compose down && docker compose up -d --build` |
| New models/schemas added | Restart is fine (Mongoose auto-registers) |
| Docker Compose file changed | `docker compose down && docker compose up -d --build` |
| Env vars changed | `docker compose down && docker compose up -d` |
| Strange build errors | `docker compose down -v && docker compose up -d --build` (nuclear — rebuilds everything including volumes) |

---

## For AI Agents: Auto-Detection

When an AI agent starts a session (`session start`, `agent mode`, or `hello`), it MUST:

1. **Check the last session's machine** — compare the hostname in `AI_AGENT_HANDOFF.md` or `claude_log.md` with the current hostname (`hostname` command).
2. **If different machine** — execute the full checklist above before any other work.
3. **If same machine** — skip to normal session start, but still check for Dropbox conflicts.

### Hostname Detection

```bash
# Get current machine name
hostname -s
# e.g. "PH11911" (work) or "Rummans-MacBook-Pro" (home)
```

Agents should log the hostname in `claude_log.md` on every session start so the next session can compare.

---

## Session Close: Machine Handoff

When closing a session, the agent MUST:

1. **Ensure all changes are committed and pushed** — the other machine gets code via both Dropbox AND git. Git is the authoritative source; Dropbox is the fast sync.
2. **Log the current hostname** in `AI_AGENT_HANDOFF.md`:
   ```
   > Last machine: PH11911
   ```
3. **Stop Docker containers** (optional but recommended to prevent port conflicts and stale state):
   ```bash
   docker compose stop
   ```

---

## Dropbox .gitignore Best Practices

Ensure these are in `.gitignore` to reduce Dropbox sync noise:

```
node_modules/
.next/
*.lock
.git/gk/
```

The `.git/gk/` directory (GitKraken) is the biggest offender for Dropbox conflicts — 67 conflict files were cleaned up in the 2026-03-23 session.

---

## Quick Reference

```
Machine switch? → Wait for Dropbox sync → Clean conflicts → docker compose up -d --build → Verify
Same machine?   → Check for conflicts → docker compose restart app (if needed) → Continue
```
