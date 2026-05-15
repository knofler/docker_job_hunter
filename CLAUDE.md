# Claude Code — Project Routing Rules

> This file is read by Claude Code at project startup. It defines how to route tasks to specialist subagents and when to dispatch in parallel.

---

## CRITICAL RULES (read before doing anything)

1. **NEVER push directly to `main`.** All code goes to `test` branch first. Push to `test` → verify preview → PR to `main` → merge. This is non-negotiable.
2. **NEVER run `npm install`, `npm ci`, `npx`, or `node` on the host machine.** Always use `docker compose exec app <command>`. Only exception: CI runners.
3. **NEVER commit `node_modules/`, `.env`, or secrets.** Check `.gitignore` before staging.
4. **Docker container naming:** All `container_name` in `docker-compose.yml` MUST use the **exact folder name** as prefix (preserve casing): `{folderName}-app`, `{folderName}-mongo`, `{folderName}-api`. Example: folder `agentFlow` → `agentFlow-app`, `agentFlow-mongo`. If non-compliant → `docker compose down`, fix names, rebuild.
5. **Frontend standard: Tailwind CSS + shadcn/ui.** All Next.js projects use Tailwind v4 (CSS-first `@theme` config) + shadcn/ui components. Utility-first classes only — no CSS modules, no styled-components, no inline styles. Design tokens in `globals.css`, shadcn components in `src/components/ui/`, `cn()` helper in `src/lib/utils.ts`. Full guide: `AI/documentation/DESIGN_SYSTEM.md`.
6. **Git email fix (auto-fix on push failure).** If `git push` fails with `GH007` or `email privacy`, fix immediately — do NOT ask the user. Run: `git config user.email "3438317+knofler@users.noreply.github.com"` then amend with `GIT_COMMITTER_EMAIL="3438317+knofler@users.noreply.github.com" GIT_COMMITTER_NAME="Rumman Ahmed" git commit --amend --no-edit --author="Rumman Ahmed <3438317+knofler@users.noreply.github.com>"`. Both author AND committer must use noreply. Never change `--global` config.
7. **API documentation is mandatory.** Any project with API endpoints MUST have: (a) OpenAPI 3.0 spec at `/api/openapi.json`, (b) Scalar interactive docs at `/docs` (`@scalar/nextjs-api-reference`), (c) OpenAPI MCP server in `.claude/mcp.json`. Every new endpoint must be added to the OpenAPI spec — undocumented endpoints are not complete. Templates: `AI/templates/api/`.

---

## Keyword Execution Protocol (MANDATORY for all keywords)

When executing ANY keyword (`ship it`, `make prod`, `make preview`, `agent mode`, etc.), you MUST follow this protocol:

1. **Announce**: Before starting, list ALL steps you will execute as a numbered checklist.
2. **Report per step**: Before each step, say what you're about to do. After each step, report the result (done/skipped/failed).
3. **No silent steps**: Never perform a step without announcing it first and reporting the outcome.
4. **Summary table**: After ALL steps are complete, output a summary table:

```
| # | Step | Status | Notes |
|---|------|--------|-------|
| 1 | Commit changes | Done | 3 files changed |
| 2 | Push to test | Done | CI triggered |
| 3 | Wait for CI | Done | All checks passed |
| ... | ... | ... | ... |
```

Status values: `Done`, `Skipped` (with reason), `Failed` (with error).

This protocol is **mandatory** — never skip the announcement, per-step reporting, or summary table.

---

## On Session Start

1. **Multi-machine check** (MANDATORY): Run `hostname -s`, compare with `Last machine:` in `AI/state/AI_AGENT_HANDOFF.md`. If different machine → clean Dropbox conflicts, rebuild Docker (`docker compose down && docker compose up -d --build`), verify build. See `AI/documentation/MULTI_MACHINE_WORKFLOW.md`.
2. **2 GB RAM ceiling check** (MANDATORY — auto-runs via hook `hooks/session/13-ram-guard.sh`): This project's Docker stack must not exceed 2 GB total RAM. Hook sums `docker stats` across project containers and warns if over. Fix: add `mem_limit` to compose services (suggested split: app 1g + db 512m + sidecars 512m). Exempt a heavy-model repo with `touch .ram-exempt`.
3. Read `AI/state/STATE.md` and `AI/state/AI_AGENT_HANDOFF.md` to synchronize project context
4. Read `AI/documentation/AI_RULES.md` for technical mandates
5. Review `AI/documentation/MULTI_AGENT_ROUTING.md` for routing reference
6. Dispatch `project-manager` to assess current status and identify the next work priority

---

## CLI-Mobile Agent Workflow (Codeclot Branch Strategy)

This framework enables seamless mobility between **mobile Claude** (phone/tablet/browser) and **CLI Claude** (desktop/laptop). Every repo is self-contained — open any repo on any device and `agent mode` gives you full context immediately.

### The Cycle

```
MOBILE SESSION                          CLI SESSION
─────────────                           ───────────
1. agent mode                           1. agent mode
   → fetch origin                          → fetch origin
   → pull latest main                      → pull latest on current branch
   → read state + handoff                  → merge codeclot* branches
   → checkout codeclot from main           → delete merged codeclot
   → full context available                → read state + handoff

2. Do work (code, fix, plan)            2. Do work (code, fix, plan)

3. wrap up                              3. ship it
   → commit ALL to codeclot branch          → push to test → CI → PR → merge main
   → push codeclot to remote                → state + handoff updated on main
   → state + handoff in codeclot         4. wrap up
                                            → push state to test/main
                                            → all changes on main for next mobile
```

### Auto-Detection
- The multi-machine check hook detects hostname. If hostname is `vm` (cloud sandbox), the session is classified as a **mobile/cloud session**.
- Mobile/cloud sessions use `codeclot` as their working branch instead of `test`.
- Override: set env var `CODECLOT_OVERRIDE=1` to force codeclot behavior on any hostname, or `CODECLOT_OVERRIDE=0` to disable on `vm`.

### Branch Naming
- **Default:** `codeclot` — the primary mobile session branch
- **Claude Code web auto-branches:** Claude Code web/mobile auto-creates branches named `claude/agent-mode-*` or `claude/*`. These are treated identically to `codeclot` branches — they are mobile sync branches.
- **Multiple unmerged sessions:** If `codeclot` already exists on remote with unmerged changes, create `codeclot/<YYYYMMDD-HHMM>` (e.g., `codeclot/20260405-1430`)
- Timestamp branches ensure session isolation — no overwrites between mobile sessions
- **Pattern match for all mobile branches:** `codeclot*` OR `claude/*` — CLI agent mode must check BOTH patterns

### On `agent mode` (Mobile/Cloud Session) — MANDATORY FIRST STEPS

**CRITICAL: You MUST pull latest `main` before doing ANYTHING else. Do NOT skip this. Do NOT just read state files. The code on your branch is stale — `main` has the latest from CLI sessions.**

1. `git fetch origin` — get all remote updates
2. `git checkout main && git pull origin main` — **get latest production code** (CLI sessions merge here via PR). This is the MOST IMPORTANT step. Without it, you are working on stale code.
3. Read `AI/state/AI_AGENT_HANDOFF.md` and `AI/state/STATE.md` — these are NOW up-to-date because you pulled main
4. Create or checkout working branch from latest main: `git checkout -b codeclot` (or `codeclot/<timestamp>` if codeclot exists on remote with unmerged changes). If Claude Code web auto-created a branch like `claude/agent-mode-*`, that's fine — just make sure it's based on latest main: `git merge main` into it.
5. Now the mobile agent has ALL latest code + context from the last CLI session
6. Continue with normal agent mode workflow (report status, dispatch work)

**Why this matters:** CLI sessions push code + state to `main` via PR. If mobile doesn't pull `main` first, it works on old code and old state. The whole CLI-Mobile cycle breaks.

### On `agent mode` (CLI Session — Mobile Branch Merge Step)
CLI sessions MUST merge any pending mobile work before starting:
1. `git fetch origin` — get all remote updates
2. Pull latest on current branch: `git pull origin <current-branch>`
3. List all mobile sync branches: `git branch -r | grep -E 'codeclot|claude/'`
4. If any exist:
   a. For each mobile branch, diff against `main` to assess scope and changes
   b. Report what each branch contains (files changed, summary)
   c. Merge each into current working branch
   d. After successful merge, delete the merged branch (local + remote)
5. If merge conflicts exist → report details and **ask user** before proceeding
6. Continue with normal agent mode workflow

### On `wrap up` (Mobile/Cloud Session)
In addition to the standard wrap-up workflow:
1. Commit ALL changes (code + AI state + handoff + logs) to the working branch (`codeclot` or `claude/*`)
2. Push to remote: `git push -u origin <branch>`
3. Update `AI/state/AI_AGENT_HANDOFF.md` with: branch name, summary of changes, merge-readiness status
4. YOLO god mode auto-commits are compatible — push is non-interactive

### On `wrap up` / `ship it` (CLI Session)
After shipping code to main:
1. State files (STATE.md, AI_AGENT_HANDOFF.md, logs) are committed to `test` and merged to `main`
2. This ensures the NEXT mobile session that pulls `main` gets full context
3. Always update handoff with: what was done, what's next, current blockers

### Safety Rules
- `codeclot` and `claude/*` branches are **sync branches only** — never deployed to production
- Mobile → `main` merge follows normal review process (via `ship it` or PR on CLI)
- When `ship it` runs after merging mobile branches, all changes go through CI/review
- Run `agent mode` regularly on each repo to prevent stale mobile branch accumulation
- `health_check.sh` will flag repos with unmerged mobile branches older than 7 days
- Every repo is self-contained: STATE.md, AI_AGENT_HANDOFF.md, logs, agents, skills — mobile Claude needs nothing else

---

## Specialist Subagents Available

Claude Code auto-discovers agents from `AI/.claude/agents/` and skills from `AI/.claude/skills/`:

| Agent | Trigger Keywords |
|-------|-----------------|
| `solution-architect` | architecture, design, ADR, scalability, "should we use X or Y" |
| `frontend-specialist` | component, page, frontend, UI, Next.js, React, Vercel |
| `api-specialist` | endpoint, route, API, controller, middleware, REST, GraphQL |
| `database-specialist` | schema, model, query, database, MongoDB, index, migration |
| `devops-specialist` | docker, deploy, pipeline, environment, CI/CD, GitHub Actions |
| `ui-ux-specialist` | design system, layout, style, UX, accessibility, Tailwind |
| `security-specialist` | security, auth, JWT, permissions, OWASP, rate limit |
| `documentation-specialist` | docs, README, document, guide, changelog |
| `product-manager` | feature, requirement, user story, roadmap, MVP, backlog |
| `qa-specialist` | test, QA, coverage, E2E, unit test, bug, regression |
| `tech-ba` | requirements, data flow, gap analysis, functional spec, business rule |
| `tech-lead` | code review, standards, coherence, technical decision, review |
| `project-manager` | project plan, milestone, blocker, risk, status, sprint, track |

---

## Parallel Dispatch Rules

### Always Parallel (no dependencies)
```
Lane C (Infrastructure) — start immediately on any project:
  devops-specialist: Docker + docker-compose + env vars + CI/CD
  security-specialist: auth approach + secrets review

Lane D (Async) — always parallel:
  documentation-specialist: README skeleton
  project-manager: STATE.md update + task tracking
  solution-architect: ADRs for major decisions
  product-manager: feature specs
  tech-ba: requirements documentation
```

### Parallel When No Shared State
```
Lane A (Frontend): frontend-specialist + ui-ux-specialist
Lane B (Backend):  api-specialist + database-specialist

Lanes A and B can run in parallel when API contracts are pre-defined.
```

### Sequential When Output is a Dependency
```
database-specialist schema → THEN api-specialist services
api-specialist contracts → THEN frontend-specialist fetch logic
devops-specialist env setup → THEN any implementation that references env vars
solution-architect ADR → THEN implementation of that architectural decision
```

---

## Project-Type Dispatch

### New Next.js App
```
Immediate parallel:
  frontend-specialist, ui-ux-specialist, devops-specialist, documentation-specialist, project-manager

Then (after contracts defined):
  api-specialist, database-specialist

Always parallel:
  security-specialist, qa-specialist, solution-architect
```

### API-Heavy Project (Node.js or Python)
```
Immediate parallel:
  api-specialist, database-specialist, devops-specialist, security-specialist, documentation-specialist

Async parallel:
  solution-architect, tech-ba, project-manager

Then if UI needed:
  frontend-specialist, ui-ux-specialist
```

### Any Project — Always Start With
```
devops-specialist → Docker + env vars
security-specialist → auth + .env review
documentation-specialist → README
project-manager → STATE.md
```

---

## MCP Servers (Auto-Configured)

MCP servers are configured in `.claude/mcp.json` and auto-managed by `update_all.sh`.

### Base (All Projects)
| Server | Purpose |
|--------|---------|
| **Context7** | Version-specific library docs in-context (Next.js, React, Mongoose, etc.) |
| **shadcn/ui** | Browse, search, install shadcn components |
| **Playwright** | E2E browser testing — navigate, click, fill forms, assert, screenshot |
| **ai-framework** | Local gateway (when running Docker) |

### Conditional (Auto-Detected)
| Server | Condition | Purpose |
|--------|-----------|---------|
| **Chrome DevTools** | Web project (has `next.config.*`, `vercel.json`, or `src/app/layout.tsx`) | Browser console, network, screenshots, error tracking |
| **Google Stitch** | Web project (auto-added with Chrome DevTools) | AI UI design — generate components from prompts, access design tokens |
| **Docker** | Docker project (has `docker-compose.yml`) | Container logs, exec, management. Uses `{folderName}-*` naming convention |
| **OpenAPI** | API project (has `src/app/api/`, `src/routes/`, or `routes/`) | Exposes API endpoints as MCP tools from OpenAPI spec at `/api/openapi.json` |

### API-Key Servers (Add When Ready)
See `AI/plan/MCP_SERVERS.md` for the full list: Brave Search, Figma, Sentry, MongoDB Atlas, Vercel, Upstash, Notion, Slack.

---

## Skills (60 Playbooks)

Each agent has 3-5 skills — repeatable playbooks auto-discovered from `AI/.claude/skills/`. Skills trigger when your prompt matches their keywords.

See `AI/skills/README.md` for the full catalog.

---

## Quick Keywords

The user may type these short phrases instead of full prompts. Execute the full workflow described:

| Keyword | Action |
|---------|--------|
| `hello` | Show all available keywords and their usage as a table. |
| `start work` | **0. Multi-machine check (MANDATORY):** Run `hostname -s`, read `Last machine:` from `AI/state/AI_AGENT_HANDOFF.md`. If different → read `AI/documentation/MULTI_MACHINE_WORKFLOW.md` and execute the full checklist: clean Dropbox conflicts, rebuild Docker (`docker compose down && docker compose up -d --build`), verify build. **1.** Read `AI/state/STATE.md` + `AI/state/AI_AGENT_HANDOFF.md`. Assess status. Report what's done, in-progress, blocked. Identify next priority. |
| `agent mode` | **Full multi-agent activation.** 0. **Project identity:** Display current project/repo name prominently. 0a. **Git sync (MANDATORY — DO THIS FIRST, BEFORE READING ANY FILES):** `git fetch origin`. Then: **Mobile session** (hostname = `vm` or `CODECLOT_OVERRIDE=1`): `git checkout main && git pull origin main` to get ALL latest code + state from CLI sessions, then create working branch (`codeclot` or `codeclot/<timestamp>`). **CLI session** (any other hostname): `git pull origin <current-branch>` to get latest remote. **You MUST pull before reading state files — state on disk may be stale.** 0b. **Multi-machine check:** Run `hostname -s`, compare with handoff. If different → full checklist. 0c. **Docker naming check:** Verify all `container_name` in docker-compose.yml use `{reponame}-` prefix. If not → `docker compose down`, fix names, `docker compose up -d --build`. 0d. **Mobile branch merge (CLI only, MANDATORY):** Check for any `codeclot*` or `claude/*` remote branches (`git branch -r \| grep -E 'codeclot\|claude/'`). If found: diff each against `main`, report contents, merge into current working branch, delete merged branches (local + remote). If conflicts → ask user. See "CLI-Mobile Agent Workflow" section. **0e. Fresh-blueprint onboarding (MANDATORY when applicable):** Check for `AI/state/.awaiting-app-idea`. If present, this is a fresh Powerhouse Blueprint scaffold and the user has not yet told us what to build. Execute the onboarding flow and **skip the normal agent-mode reporting (steps 1–4)**: (a) Read the marker for `scaffolded_at`, `template`, `project`, `gh_repo`. (b) Greet the user with: `🎉 Welcome to your new {project} blueprint! Tech stack is wired up. To build your app, tell me what you want to build — describe it in plain English (the more detail the better — purpose, users, key features, constraints).` (c) Wait for the user's next message — that is the app idea. (d) Save it to `AI/state/APP_IDEA.md` with frontmatter (`captured_at`, `project`, `template`) followed by the raw idea. (e) Delete `AI/state/.awaiting-app-idea`. (f) Run the autonomous 8-stage generate pipeline against the captured idea: **idea → plan → brd → gap-analysis → trd → design → build → ship**. For each stage: dispatch the appropriate specialist agent (plan: solution-architect, brd: tech-ba + product-manager, gap-analysis: tech-ba, trd: solution-architect + api-specialist + database-specialist, design: ui-ux-specialist + frontend-specialist, build: frontend + api + database in parallel, ship: tech-lead review → push to `test`). Commit each stage as it completes with message `feat(stage-N): <stage-name> complete`. (g) After the **build** stage, pause and tell the user: `Stages complete. Review the changes (git log, browse code), then say 'ship it' to push to main, or describe changes you want.` Stop there — do not auto-merge to main. (h) Update STATE.md + handoff after each stage. 1. Read state + handoff + AI_RULES + MULTI_AGENT_ROUTING. 2. Load SONA context (patterns relevant to current work). 3. Report: completed, in-progress/blocked, next priority. 3b. **Connect Hub check:** If Connect Hub is installed (check for `src/models/BugReport.ts` or `src/app/api/connect/`), run `check bugs` (list open bugs by severity) and `check features` (list open feature requests by priority/votes). Report findings as part of the status. 3c. **MCP server check:** Read `.claude/mcp.json` (if exists) and report which MCP servers are available for this project. List each server name and its purpose. MCP servers provide extended tools: **Context7** (library docs), **shadcn/ui** (component browser), **Playwright** (E2E browser testing), **Chrome DevTools** (browser console/network — web projects), **Docker** (container logs/exec — Docker projects), **ai-framework** (local gateway). User-level servers (Claude in Chrome, Google Drive) are also available if installed. Report: "MCP: [server1], [server2], ..." or "MCP: no .claude/mcp.json found". 4. Dispatch all relevant lanes in parallel — A (frontend + ui-ux), B (api + database), C (devops + security), D (docs + architect + PM), Cross (tech-lead + QA). 5. Auto-update state and logs after every task. |
| `ship it` | **Safe deployment via test branch.** 1. Commit all changes with descriptive message. 2. Push to `test` branch (NEVER directly to `main`). 3. Wait for CI to pass (lint, type-check, test). 4. Verify Vercel preview deployment succeeded. 5. Ask user to test the preview URL. 6. When user confirms, create PR `test` → `main` with summary. 7. Run AI code review on the PR. 8. When all checks pass, merge the PR. 9. Confirm production deployment complete. 10. **Post-merge review check:** Run `gh api repos/{owner}/{repo}/pulls/{pr}/reviews` and `gh api repos/{owner}/{repo}/pulls/{pr}/comments` to pull any automated reviewer comments (Copilot, CodeQL, etc.). If findings exist, assess each — fix valid issues in a follow-up PR, note invalid ones. Report what was found and actioned. 11. Update `AI/state/STATE.md` + `AI/state/AI_AGENT_HANDOFF.md` + `AI/logs/claude_log.md`. **Do NOT run update_all — this is a project, not the master repo.** 12. **Sync test with main (MANDATORY):** `git fetch origin && git merge origin/main --no-edit` — keeps test aligned with main so branch state is honest and wrap-up banner reflects the truth. |
| `wrap up` | **Session close with traffic-light dashboard.** 1. Run session-close (summarize, update STATE.md, handoff, log). 2a. **Mobile/cloud session:** If hostname = `vm` (or `CODECLOT_OVERRIDE=1`), commit ALL changes (code + state + handoff + logs) to `codeclot` branch. If `codeclot` exists on remote with unmerged changes, use `codeclot/<YYYYMMDD-HHMM>` instead. Push to remote. Note codeclot branch name in handoff. 2b. **CLI session:** Commit state + handoff + logs. Push to current branch. Ensure state files reach `main` (via ship it or direct push) so the next mobile session gets full context. 3. Show dashboard: `[OK]` green, `[!!]` yellow, `[XX]` red for: commit, push, STATE.md, handoff, branch, Docker, CI. 4. If all green → "Safe to close". If red → list what needs fixing. 5. **WRAPPED UP banner (MANDATORY):** As the very last output, display the ASCII art WRAPPED UP banner. Fill in dynamically: REPO (folder name + standalone/master), BRANCH (current git branch), REMOTE (git remote URL), SESSION (CLI or Mobile + hostname), WRAPPED (current UTC timestamp), PRs (any merged this session), STATUS (summary). Use 🟢 dots for detail lines. This banner must be the final visible output so returning to a closed session immediately shows it was wrapped up. |
| `status` | Read `AI/state/STATE.md` and give a quick summary: done, in-progress, blocked, next priority. |
| `review` | Dispatch `tech-lead` for code review + `qa-specialist` for test coverage check on recent changes. |
| `plan [feature]` | Dispatch `solution-architect` + `product-manager` + `tech-ba` to break down a feature into specs, stories, and ADR before code. |
| `scaffold [thing]` | Generate boilerplate via relevant specialists: `scaffold api`, `scaffold page [name]`, `scaffold schema [name]`, `scaffold docker`, `scaffold tests`. |
| `audit` | Dispatch `security-specialist` (OWASP) + `qa-specialist` (coverage) + `tech-lead` (standards) in parallel. |
| `handoff` | Prepare full handoff: update STATE.md, write detailed AI_AGENT_HANDOFF.md, log session — ready for a different AI agent. |
| `list` | **Audit all managed repos.** Read `config/managed_repos.txt` from the AI master repo, check each path for: AI/ folder exists, STATE.md exists, CLAUDE.md exists, GEMINI.md exists. Output a markdown table with columns: Project, Level (standalone/workspace root/sub-repo), AI/, STATE.md, CLAUDE.md, GEMINI.md. Bold workspace roots and standalones. |
| `show urls` | Show all deployment URLs for this project: production (main branch) and preview (test branch). Check `.vercel/project.json` for Vercel project name, `render.yaml` for Render. Production: `https://{project}.vercel.app`. Preview: `https://{project}-git-test-{org}.vercel.app`. |
| `check bugs` | Pull open bugs from the Connect Hub DB (`BugReport` collection). List by severity. Suggest which to fix first based on severity and age. |
| `fix bug [id]` | Pull bug details from DB. Set status to "working". Analyse root cause, implement fix on `test` branch, push, create PR. Update bug: status → "solved", resolution, prUrl. |
| `check features` | Pull open feature requests from DB (`FeatureRequest` collection). List by priority and upvotes. Suggest which to implement first. |
| `build feature [id]` | Pull feature details from DB. Set status to "working". Generate implementation plan, implement on `test` branch, push, create PR. Update feature: status → "solved", prUrl. |
| `triage` | Pull all "reported" bugs and features from DB. AI analyses each: set severity/priority, detect duplicates, assign to specialist agent, update status to "triaged". |
| `merge it` | Merge `test` → `main` via PR. Create PR if not exists, verify CI passes, merge, update any bug/feature DB status from "solved" to "deployed" with `deployedAt` timestamp. Confirm production deployment complete. |
| `connect setup` | **Integrate Connect Hub into this project.** 1. Read `AI/documentation/CONNECT_HUB.md` — this is the FULL instruction doc with every step. 2. Check if Connect Hub files exist in `src/models/BugReport.ts`, `src/app/api/connect/`, `src/app/connect/`. If missing, tell user: "Connect Hub files not found. Run this from the master AI repo first: `./scripts/init_connect.sh /path/to/this/project`". 3. If files exist, follow Steps 1-8 in CONNECT_HUB.md: verify files → fix import placeholders (`__DB_IMPORT__`, `__AUTH_IMPORT__`, `__MODELS_PATH__`) → update middleware → update model barrel exports → add nav item → type check → test → report summary table. |
| `make preview` | **Set up the test→preview pipeline for this repo.** 1. Create `test` branch from `main` if not exists. 2. Push `test` to remote. 3. Add CI workflows (`.github/workflows/ci.yml` + `merge-gate.yml`) if missing. 4. Set branch protection via `gh` CLI. 5. Sync `test` with latest `main`. 6. Report preview URL. |
| `make prod` | **Productionise this project with branching strategy.** 0. **Check first:** Look for existing Vercel config, Render config, Atlas connection. If already configured → verify health, report status, done. 1. **Set up branching:** Create `test` branch, add CI workflows (`.github/workflows/ci.yml` + `merge-gate.yml`), set branch protection rules. 2. **Provision infrastructure:** Detect project type (Next.js → Vercel, Express → Render, MongoDB → Atlas). Create Vercel project + deploy from `main`. Set env vars for both Production and Preview environments. 3. **Verify:** Push test commit to `test` branch, confirm CI passes + Vercel preview deploys. Verify health endpoint. 4. **Update:** State files with production URLs + preview URL pattern. |
| `remote` | Start `claude remote-control` for this project. Run `./AI/scripts/remote.sh` — prints QR code/URL to connect from phone, tablet, or browser. Session runs locally. See `AI/documentation/MOBILE_CONTROL.md`. |
| `telegram setup` | Run guided Telegram bot setup: `./AI/scripts/telegram-setup.sh`. Checks Bun installed, installs plugin, configures bot token, prints next steps for pairing and lockdown. See `AI/documentation/MOBILE_CONTROL.md`. |
| `telegram start` | Launch Claude Code with Telegram channel active: `claude --channels plugin:telegram@claude-plugins-official`. Requires prior setup via `telegram setup`. |
| `ai tools` | **Fleet inventory — show 5 of each.** 1. Try live gateway first: `curl -s http://localhost:3100/mcp` for MCP tools, `curl -s http://localhost:3200/api/agents` + `/api/skills` for counts. If gateway down, fall back to reading `AI/agents/`, `AI/skills/`, and the master repo's `runtime/src/mcp/tools.ts`. 2. Print four sections of 5 rows each: **Agents** (name, category, one-line), **Skills** (name, description, triggers), **MCP Tools** (name, category, purpose), **Gateway Routes** (one row per surface: `:3100` MCP, `:3200` REST, `:3201` WS, `:3210` dashboard). 3. End each section with `… N more — run "more <type>" to see all`. Full reference lives in the master repo's README. |
| `more agents` | Expand the `ai tools` agents block — list all 57 agents grouped by category. |
| `more skills` | Expand the `ai tools` skills block — list all 135 skills with triggers. |
| `more mcp` / `more mcp tools` | Expand all 15 MCP tool definitions with input schemas (pull from `http://localhost:3100/mcp` `tools/list`). |
| `more routes` | Expand every HTTP (`:3200`), WebSocket (`:3201`), MCP (`:3100`), and dashboard (`:3210`) route. |
| `ai tools help` / `help ai tools` | Print the `ai tools` usage block (default behavior + sub-commands + data sources). |
| `yolo [minutes]` | **Timed autonomous mode.** `yolo 10` = for the next 10 minutes, do NOT ask any permission or clarifying questions. Execute all actions (file writes, bash commands, git operations, agent dispatches) without pausing. Run `./AI/scripts/yolo.sh start <minutes>`. On every action, check `AI/state/.yolo` — if expired, revert to normal mode. Show a countdown reminder every 3rd action. |
| `yolo god` | **Full autonomous mode until completion.** No questions asked until the current plan is finished OR the next `git commit` is created — whichever comes first. Run `./AI/scripts/yolo.sh start god`. The agent proceeds with maximum velocity: pick the best approach, execute it, move on. If something fails, diagnose and fix without asking. On commit or plan completion, auto-deactivate by running `./AI/scripts/yolo.sh stop`. |
| `yolo off` | **Deactivate YOLO mode immediately.** Run `./AI/scripts/yolo.sh stop`. Resume normal permission behavior. |

---

## Wrap Up Banner (MANDATORY on every session close)

The `wrap up` keyword MUST end with this ASCII banner as the **final output**. Fill in values dynamically from git and session context. This makes it instantly visible when scrolling back to a closed session.

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ██╗    ██╗██████╗  █████╗ ██████╗ ██████╗ ███████╗██████╗     ║
║   ██║    ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗   ║
║   ██║ █╗ ██║██████╔╝███████║██████╔╝██████╔╝█████╗  ██║  ██║   ║
║   ██║███╗██║██╔══██╗██╔══██║██╔═══╝ ██╔═══╝ ██╔══╝  ██║  ██║   ║
║   ╚███╔███╔╝██║  ██║██║  ██║██║     ██║     ███████╗██████╔╝   ║
║    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚═════╝    ║
║                                                                  ║
║          ██╗   ██╗██████╗     ██╗                                ║
║          ██║   ██║██╔══██╗    ██║                                ║
║          ██║   ██║██████╔╝    ██║                                ║
║          ██║   ██║██╔═══╝     ╚═╝                                ║
║          ╚██████╔╝██║         ██╗                                ║
║           ╚═════╝ ╚═╝         ╚═╝                                ║
║                                                                  ║
║──────────────────────────────────────────────────────────────────║
║                                                                  ║
║   🟢 REPO:     {folder name} ({standalone/master/sub-repo})      ║
║   🟢 BRANCH:   {current git branch}                              ║
║   🟢 REMOTE:   {git remote url}                                  ║
║   🟢 SESSION:  {CLI/Mobile} ({hostname})                         ║
║   🟢 WRAPPED:  {YYYY-MM-DD HH:MM UTC}                            ║
║                                                                  ║
║   🟢 PRs:      {any PRs merged this session, or "none"}          ║
║   🟢 STATUS:   {summary — e.g. "All green — nothing pending"}    ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## YOLO Mode — Autonomous Execution Protocol

When YOLO mode is active (`AI/state/.yolo` exists and not expired):

1. **No clarifying questions.** Pick the best approach and execute. Don't ask "should I X or Y?" — decide and do it.
2. **No confirmation prompts.** Proceed with file writes, bash commands, git operations, Docker rebuilds without pausing.
3. **No summarizing before acting.** Skip "I'm going to do X, Y, Z" preamble — just do it and report results.
4. **Error recovery is autonomous.** If something fails, diagnose and fix. Only stop if 3 consecutive attempts at the same fix fail.
5. **Still respect safety rails:** Never push to `main`, never commit secrets, never delete branches without recovery path. YOLO skips permission prompts, not safety rules.

### Timed Mode (`yolo N`)
- Active for N minutes from activation
- Check `AI/state/.yolo` expiry before each action — if expired, delete the file and announce "YOLO expired — back to normal mode"
- Show remaining time every 3rd action: `[YOLO: 7m remaining]`

### God Mode (`yolo god`)
- Active until the next `git commit` succeeds OR the current plan/task list is fully completed
- After a successful commit: auto-run `./AI/scripts/yolo.sh stop` and announce "YOLO god mode — deactivated (commit created)"
- After plan completion: auto-run `./AI/scripts/yolo.sh stop` and announce "YOLO god mode — deactivated (plan complete)"

### Checking YOLO State
On session start, the `11-yolo-status.sh` hook checks `AI/state/.yolo`:
- If active → display mode and time remaining
- If expired → delete file, show "YOLO expired"
- If absent → no output (silent)

---

## Usage Guard Protocol — Session Capacity Management

The Usage Guard tracks session capacity via two metrics: **elapsed time** and **weighted action count** (tool calls as token proxy). The higher percentage is the effective usage level. Config: `AI/config/session-limits.json`. Metrics: `AI/state/.session-metrics`.

Hooks automatically emit warnings. **These are mandatory directives, not suggestions.**

### At 80% — YELLOW WARNING

You will see: `USAGE GUARD: YELLOW WARNING — 80% CAPACITY`

1. **Announce** to user: "Session at 80% — ~Xm and ~Y actions remaining."
2. **Finish** current task — do NOT start new work.
3. **Prioritize** remaining budget: commit > push > state update > handoff.
4. **Skip** non-essential ops: no refactors, no exploratory reads, no test runs unless critical.

### At 90% — RED WARNING

You will see: `USAGE GUARD: RED WARNING — 90% CAPACITY`

1. **Stop** all work immediately.
2. **Run `wrap up`** — full session close: summarize, STATE.md, AI_AGENT_HANDOFF.md, commit, push.
3. If `wrap up` would exceed budget, skip to 95% emergency protocol.
4. **Tell user**: "Session at 90% — wrapping up now. Continue with Gemini/Copilot using AI_AGENT_HANDOFF.md."

### At 95% — EMERGENCY (TOOL BLOCK ACTIVE)

You will see: `USAGE GUARD: EMERGENCY` and Bash/Edit/Write will be **BLOCKED** except writes to AI_AGENT_HANDOFF.md.

1. **Write `AI/state/AI_AGENT_HANDOFF.md` immediately** with minimal content:
   - What was done this session (bullet list)
   - What is in progress (branch, uncommitted files)
   - What should be done next (prioritized)
   - Current blockers
   - Last machine hostname
2. **Do NOT** attempt STATE.md, logs, SONA, or dashboard — no budget.
3. **Do NOT** attempt git commit/push — Bash is blocked.
4. Tell user: "Emergency handoff saved. Please commit/push manually, then continue with another agent."

---

## Deployment Workflow (Branching Strategy)

**NEVER push directly to `main`. All code goes through `test` branch first.**

```
1. Push to test     →  git push origin test
2. CI runs          →  lint, type-check, test (automatic)
3. Preview deploys  →  Vercel generates preview URL (automatic)
4. User tests       →  AI asks user to verify preview URL
5. Create PR        →  gh pr create --base main --head test
6. AI reviews PR    →  code review + merge gate check
7. Merge            →  gh pr merge --merge
8. Prod deploys     →  Vercel auto-deploys to production (automatic)
9. Notify           →  AI confirms "Production deployment complete"
```

**Branch protection rules:**
- `main`: PR required, CI must pass (Lint, Type-check, Test)
- `test`: CI must pass, direct push allowed

**Docker-only development:** NEVER run `npm install`, `npm ci`, `npx`, or `node` directly on the host machine. Always use `docker compose exec app <command>`. The only exception is CI runners (GitHub Actions).

---

## Quality Gates (tech-lead enforces)

Before any feature is marked complete:
- [ ] API contracts match frontend implementation
- [ ] Database schema matches service queries
- [ ] Auth middleware matches security-specialist spec
- [ ] Tests exist (qa-specialist sign-off)
- [ ] Documentation updated
- [ ] CI/CD pipeline passes

---

## State Management Protocol

```
Session start:  Read AI/state/STATE.md + AI/state/AI_AGENT_HANDOFF.md
After each task: Update AI/state/STATE.md autonomously — do not wait for user prompt
Session end:    Update AI/state/STATE.md + AI/state/AI_AGENT_HANDOFF.md
Agent log:      Write to AI/logs/claude_log.md with timestamp
```

**NEVER wait for the user to ask you to save state.** Update state/STATE.md after every significant action.

---

## File Domain Ownership (No Parallel Writes to Same Files)

| Domain | Owned By | Files |
|--------|---------|-------|
| Frontend | frontend-specialist | `src/app/`, `src/components/`, `styles/` |
| API | api-specialist | `src/routes/`, `src/controllers/`, `src/services/` |
| Database | database-specialist | `src/models/`, `src/db/` |
| Infra | devops-specialist | `docker-compose.yml`, `.github/`, `Dockerfile` |
| Auth/Security | security-specialist | `src/middleware/auth.js`, `src/middleware/security.js` |
| AI/Docs | Lane D agents | `AI/`, `README.md`, `docs/` |
