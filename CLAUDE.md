# Claude Code — Project Routing Rules

> This file is read by Claude Code at project startup. It defines how to route tasks to specialist subagents and when to dispatch in parallel.

---

## CRITICAL RULES (read before doing anything)

1. **NEVER push directly to `main`.** All code goes to `test` branch first. Push to `test` → verify preview → PR to `main` → merge. This is non-negotiable.
2. **NEVER run `npm install`, `npm ci`, `npx`, or `node` on the host machine.** Always use `docker compose exec app <command>`. Only exception: CI runners.
3. **NEVER commit `node_modules/`, `.env`, or secrets.** Check `.gitignore` before staging.
4. **Docker container naming:** All `container_name` in `docker-compose.yml` MUST use the **exact folder name** as prefix (preserve casing): `{folderName}-app`, `{folderName}-mongo`, `{folderName}-api`. Example: folder `agentFlow` → `agentFlow-app`, `agentFlow-mongo`. If non-compliant → `docker compose down`, fix names, rebuild.

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
2. Read `AI/state/STATE.md` and `AI/state/AI_AGENT_HANDOFF.md` to synchronize project context
3. Read `AI/documentation/AI_RULES.md` for technical mandates
4. Review `AI/documentation/MULTI_AGENT_ROUTING.md` for routing reference
5. Dispatch `project-manager` to assess current status and identify the next work priority

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
| `agent mode` | **Full multi-agent activation.** 0. **Project identity:** Display current project/repo name prominently. 0b. **Multi-machine check:** Run `hostname -s`, compare with handoff. If different → full checklist. 0c. **Docker naming check:** Verify all `container_name` in docker-compose.yml use `{reponame}-` prefix. If not → `docker compose down`, fix names, `docker compose up -d --build`. 1. Read state + handoff + AI_RULES + MULTI_AGENT_ROUTING. 2. Load SONA context (patterns relevant to current work). 3. Report: completed, in-progress/blocked, next priority. 4. Dispatch all relevant lanes in parallel — A (frontend + ui-ux), B (api + database), C (devops + security), D (docs + architect + PM), Cross (tech-lead + QA). 5. Auto-update state and logs after every task. |
| `ship it` | **Safe deployment via test branch.** 1. Commit all changes with descriptive message. 2. Push to `test` branch (NEVER directly to `main`). 3. Wait for CI to pass (lint, type-check, test). 4. Verify Vercel preview deployment succeeded. 5. Ask user to test the preview URL. 6. When user confirms, create PR `test` → `main` with summary. 7. Run AI code review on the PR. 8. When all checks pass, merge the PR. 9. Confirm production deployment complete. 10. Update `AI/state/STATE.md` + `AI/state/AI_AGENT_HANDOFF.md` + `AI/logs/claude_log.md`. **Do NOT run update_all — this is a project, not the master repo.** |
| `wrap up` | **Session close with traffic-light dashboard.** 1. Run session-close (summarize, update STATE.md, handoff, log). 2. Show dashboard: `[OK]` green, `[!!]` yellow, `[XX]` red for: commit, push, STATE.md, handoff, branch, Docker, CI. 3. If all green → "Safe to close". If red → list what needs fixing. |
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
