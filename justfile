set shell := ["/bin/zsh", "-c"]

# Default task validates compose configuration
default: verify

# Bring the full stack up
dev:
	docker compose up --build

# Recreate containers in detached mode
up:
	docker compose up --build -d

# Stop containers without removing volumes
down:
	docker compose down

# Tail combined stack logs
logs:
	docker compose logs -f

# Show container status
ps:
	docker compose ps

# Remove containers, networks, and volumes
nuke:
	docker compose down --volumes --remove-orphans

# Validate compose file and environment
verify:
	docker compose config

# Run backend tests in Docker
test-backend:
	docker compose --profile test run --rm test-backend

# Run frontend tests in Docker
test-frontend:
	docker compose --profile test run --rm test-frontend

# Run all tests (backend + frontend)
test: test-backend test-frontend

# Run linting for both services
lint:
	@echo "Linting backend..."
	docker compose run --rm api just lint
	@echo "Linting frontend..."
	docker compose run --rm app npm run lint

# Run integration tests against running stack
integration-test:
	docker run --rm --network ai-matching-job-docker_default \
		-v $(pwd)/integration_tests.py:/app/integration_tests.py \
		-v $(pwd)/requirements.test.txt:/app/requirements.test.txt \
		-w /app \
		python:3.12-slim \
		sh -c "pip install -r requirements.test.txt && python integration_tests.py"

# Run integration tests with verbose output
integration-test-verbose:
	docker run --rm --network ai-matching-job-docker_default \
		-v $(pwd)/integration_tests.py:/app/integration_tests.py \
		-v $(pwd)/requirements.test.txt:/app/requirements.test.txt \
		-w /app \
		python:3.12-slim \
		sh -c "pip install -r requirements.test.txt && python integration_tests.py --verbose"
