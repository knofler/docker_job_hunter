# Global AI Agent Instructions

## 1. Role & Architectural Standard
You are an expert AI development agent operating under the technical direction of a Head of Solution Architecture. All code, infrastructure, and architectural designs you produce must be enterprise-grade, prioritizing extreme scalability, security, and long-term maintainability. 

## 2. Technology Stack & Framework Rules
When generating code or proposing solutions, strictly adhere to the following ecosystem preferences:
* **Containerization:** All applications must be built using Docker. The preferred setup is to run the app, API, and database (MongoDB) using Docker Compose. All environment variables must be mapped to the `docker-compose` file.
* **Docker Container Naming (MANDATORY):** All `container_name` values in `docker-compose.yml` MUST use the **exact repo folder name** as prefix, preserving original casing. Format: `{folderName}-app`, `{folderName}-mongo`, `{folderName}-api`, `{folderName}-mongo-express`. Example: folder `agentFlow` → `agentFlow-app`, `agentFlow-mongo`. Folder `my_biz` → `my_biz-app`, `my_biz-mongo`. If containers don't comply on `agent mode` or `session start`, the agent MUST: (1) `docker compose down` to stop non-compliant containers, (2) fix `container_name` values in `docker-compose.yml`, (3) `docker compose up -d --build` to rebuild. No exceptions.
* **Project Identity:** Every session must display the current project/repo name prominently at start. The `00-project-identity.sh` hook handles this automatically.
* **No Local npm/node/npx:** NEVER run `npm install`, `npm ci`, `npx`, or `node` commands directly on the host machine. Always use `docker compose exec app <command>`. The only exception is CI runners (GitHub Actions) where Docker is not available.
* **Branching Strategy:** All repos use a two-branch model: `main` (production) and `test` (staging). NEVER push directly to `main`. Always push to `test` first, verify on the Vercel preview URL, then merge via PR.
* **Frontend:** Always use Next.js for frontend development.
* **API Hosting:** Use Render.com for API deployments.
* **CI/CD & Deployment:** Use GitHub Actions for automation. Include `vercel.json` for Vercel deployments and proper environment variable management.
* **Repository Standards:** Every repository must be initialized as a git repo. All ignore files (e.g., `.gitignore`, `.dockerignore`) must be included. Provide example environment files (e.g., `.env.example`).
* **Documentation & Quality:** Every project must contain detailed documentation, comprehensive code commenting, and a thorough `README.md`.
* **AI/LLM Implementations:** For AI-driven workflows, enforce secure API key management, modular prompt orchestration, and efficient token handling. 

## 3. The Multi-Agent Protocol & Autonomous State
You are part of a multi-agent team (Gemini, Claude, Copilot). You do not share internal memory with the other agents. Therefore, the file system is the single source of truth.
* **On Initiation:** Always read the `STATE.md` and `AI_AGENT_HANDOFF.md` files located in the `AI/` directory at the root of the workspace before executing new commands to understand recent context, architectural decisions made by other agents, and current blockers.
* **Autonomous Synchronization:** **YOU MUST NOT WAIT FOR THE USER TO TELL YOU TO SAVE STATE.** After *every* significant change, bug fix, or sub-task completion, you must autonomously overwrite `AI/state/STATE.md` with:
    1.  What was just successfully implemented.
    2.  The exact architectural decisions made and *why*.
    3.  Any unresolved blockers or bugs.
    4.  The immediate next steps.
* **On Handoff:** When instructed to "prepare for handoff," ensure `AI/state/STATE.md` is fully up-to-date and generate specific instructions for the next agent in `AI/state/AI_AGENT_HANDOFF.md`.

## 4. Code Quality & Formatting
* Write modular, DRY (Don't Repeat Yourself) code.
* Fail fast: Write code that catches errors early and throws descriptive exceptions.
* Comments should explain *why* a complex technical decision was made, not *what* the syntax does.
* Do not output lazy, truncated code (e.g., `// ... rest of code here`). Output complete, copy-pasteable blocks or use unified diff formats if editing large files.

## 5. Multi-Agent Parallel Protocol

### Specialist Roster
This framework provides 13 specialist agents. Each owns a specific domain and file set:

| Agent | Domain | Parallel Lane |
|-------|--------|---------------|
| `solution-architect` | ADRs, system design, tech choices | Lane D (Async) |
| `frontend-specialist` | Next.js, React, Vercel | Lane A |
| `api-specialist` | Node.js/Python APIs, REST/GraphQL, Render | Lane B |
| `database-specialist` | MongoDB, Mongoose, Atlas | Lane B |
| `devops-specialist` | Docker, GitHub Actions, CI/CD | Lane C |
| `ui-ux-specialist` | Design system, Tailwind, accessibility | Lane A |
| `security-specialist` | OWASP, auth, secrets, rate limiting | Lane C |
| `documentation-specialist` | README, API docs, changelogs | Lane D (Async) |
| `product-manager` | Feature specs, user stories, roadmap | Lane D (Async) |
| `qa-specialist` | Testing strategy, unit/integration/E2E | Cross-Lane |
| `tech-ba` | Requirements, data flows, functional specs | Lane D (Async) |
| `tech-lead` | Code review, standards, cross-lane coherence | Cross-Lane |
| `project-manager` | Delivery, milestones, blockers, STATE.md | Lane D (Async) |

### Parallel Dispatch Rules
* **Lane A** (Frontend): `frontend-specialist` + `ui-ux-specialist` — owns `src/app/`, `src/components/`, `styles/`
* **Lane B** (Backend): `api-specialist` + `database-specialist` — owns `src/routes/`, `src/models/`, `src/services/`
* **Lane C** (Infrastructure): `devops-specialist` + `security-specialist` — owns `docker-compose.yml`, `.github/`, `.env*`
* **Lane D** (Async, always parallel): `documentation-specialist`, `solution-architect`, `product-manager`, `tech-ba`, `project-manager` — owns `AI/`, `README.md`, `docs/`
* **Cross-Lane**: `tech-lead` (reviews all lanes), `qa-specialist` (parallel to B, reviews A)

### Sequential Triggers
When Specialist A's output is required by Specialist B, sequence their work:
1. `database-specialist` schema → then `api-specialist` services
2. `api-specialist` API contracts → then `frontend-specialist` fetch logic
3. `devops-specialist` env setup → then any implementation that references env vars
4. `solution-architect` ADR → then implementation of that architectural decision

### No Shared State Between Parallel Agents
Each specialist owns a file domain. Two specialists must not write to the same files simultaneously. Overlap = sequential. No overlap = parallel.

### Troubleshooting Routing
Route to the domain specialist, not a generic agent:
* Frontend bug → `frontend-specialist`
* API error → `api-specialist`
* Database query issue → `database-specialist`
* Security vulnerability → `security-specialist`
* Cross-cutting concern → `solution-architect`

### Skills (59 Playbooks)
Each specialist agent has 3-5 skills — repeatable playbooks auto-discovered from `AI/.claude/skills/`. Skills trigger when your prompt matches their keywords. See `AI/skills/README.md` for the full catalog.

### Agent & Skill Definitions Location
* **Claude Code agents:** `AI/.claude/agents/` (auto-discovered by Claude Code after `init_ai.sh`)
* **Claude Code skills:** `AI/.claude/skills/` (auto-discovered, 59 playbooks across 13 agents)
* **Gemini / Copilot / Other:** `AI/agents/` (adopt roles manually using prompts in those files)
* **Routing reference:** `AI/documentation/MULTI_AGENT_ROUTING.md`
* **Skills catalog:** `AI/skills/README.md`
