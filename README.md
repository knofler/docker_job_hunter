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