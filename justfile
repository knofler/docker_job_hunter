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

# Draft a PR for infrastructure changes
pr-draft:
	gh pr create --draft --fill
