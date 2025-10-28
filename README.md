# AI Matching Job Docker Setup

This repository contains the Docker Compose configuration to orchestrate the frontend, backend, and MongoDB services for the AI Matching Job project.

## Services
1. **Frontend**:
   - Next.js app (`ai-matching-job-app`).
   - Accessible at `http://localhost:3000`.

2. **Backend**:
   - FastAPI app (`ai-matching-job-api`).
   - Accessible at `http://localhost:8000`.

3. **MongoDB**:
   - Database for storing user and job data.
   - Accessible at `mongodb://localhost:27017`.

## Usage
1. Build and start all services:
   ```bash
   docker-compose up --build
   ```

## Automation shortcuts

Install `just` (`brew install just`) and use the predefined recipes:

```bash
just dev     # docker compose up --build (interactive)
just up      # docker compose up --build -d
just logs    # docker compose logs -f
just verify  # docker compose config
just nuke    # docker compose down --volumes --remove-orphans
just pr-draft  # gh pr create --draft --fill
```