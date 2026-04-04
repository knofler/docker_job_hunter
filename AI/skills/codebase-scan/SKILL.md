# Skill: Codebase Scan

> Agent: **solution-architect** (primary), all specialists (parallel dispatch)
> Triggers: `scan codebase`, `full scan`, `onboard project`

---

## Purpose

Perform a comprehensive scan of an entire codebase to understand its structure, detect technologies, identify issues, and produce actionable tasks. This is the entry point for onboarding any new or existing project into the AI management framework.

---

## Inputs

| Input | Source | Required |
|-------|--------|----------|
| Project root path | User or `config/managed_repos.txt` | Yes |
| Existing `state/STATE.md` | Auto-detected | No |
| Previous scan report | `reports/codebase-scan.md` | No |

---

## Steps

### 1. Integrity Gate
- Invoke `agent-integrity-check` skill before any agent dispatch.
- If integrity fails, STOP and report. Do not proceed with untrusted agents.

### 2. Tech Detection
- Scan for: `package.json`, `requirements.txt`, `Dockerfile`, `docker-compose.yml`, `vercel.json`, `.github/workflows/`, `tsconfig.json`, `tailwind.config.*`, `next.config.*`, `.env*`, `render.yaml`, `mongod` references.
- Build a technology manifest: language, framework, database, deployment target, CI/CD provider.
- Write manifest to `reports/tech-manifest.json`.

### 3. Agent Mapping
- Map detected technologies to relevant specialist agents using `documentation/MULTI_AGENT_ROUTING.md`.
- Example: `package.json` with Next.js -> `frontend-specialist`, `ui-ux-specialist`. Dockerfile -> `devops-specialist`. MongoDB connection string -> `database-specialist`.
- Produce an agent dispatch list.

### 4. Parallel Agent Dispatch
- Invoke `agent-opinion-gather` skill with the agent dispatch list.
- Each agent scans ONLY its domain (frontend scans pages/components, devops scans Docker/CI, etc.).
- Agents run in parallel across lanes A/B/C/D per `MULTI_AGENT_ROUTING.md`.

### 5. Collect Opinions
- Wait for all dispatched agents to complete.
- Read each agent's opinion from `reports/agent-opinions/{agent}.md`.
- Merge into a unified findings list with severity levels: CRITICAL, HIGH, MEDIUM, LOW.

### 6. Compile Report
- Write `reports/codebase-scan.md` with sections: Executive Summary, Tech Stack, Agent Findings (by agent), Consolidated Issues (by severity), Recommendations.
- Include timestamp and scan duration.

### 7. Create Tasks
- Invoke `auto-task-assign` skill with the scan report.
- PM agent converts findings into structured tasks in `state/tasks.json`.

### 8. Present to User
- Output a summary table: agent, findings count, critical/high issues.
- Show top 5 priority tasks.
- Ask user which lane to start executing first.

---

## Outputs

| Output | Location |
|--------|----------|
| Tech manifest | `reports/tech-manifest.json` |
| Agent opinions | `reports/agent-opinions/{agent}.md` |
| Full scan report | `reports/codebase-scan.md` |
| Task board | `state/tasks.json` |

---

## Notes

- First scan of a project may take longer due to full file tree traversal.
- Subsequent scans diff against the previous `reports/codebase-scan.md` and only re-scan changed areas.
- Always update `state/STATE.md` after scan completes.
