#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$HOME/infra-monitor"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
ENV_FILE="$PROJECT_DIR/docker/day9.env"

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

info() {
  echo "==> $1"
}

info "Starting infra-monitor deployment safety checks..."

[ -d "$PROJECT_DIR" ] || fail "Project directory not found: $PROJECT_DIR"
[ -d "$PROJECT_DIR/.git" ] || fail "Project directory exists but is not a Git repository: $PROJECT_DIR"

command -v git >/dev/null 2>&1 || fail "Git is not installed"
command -v docker >/dev/null 2>&1 || fail "Docker is not installed"

docker info >/dev/null 2>&1 || fail "Docker daemon is not running or current user cannot access Docker"
docker compose version >/dev/null 2>&1 || fail "Docker Compose plugin is not available"

[ -f "$COMPOSE_FILE" ] || fail "Docker Compose file not found: $COMPOSE_FILE"

if grep -q "day9.env" "$COMPOSE_FILE"; then
  [ -f "$ENV_FILE" ] || fail "Expected env file not found: $ENV_FILE"
fi

info "Preflight checks passed"

cd "$PROJECT_DIR"

info "Current user: $(whoami)"
info "Current host: $(hostname)"
info "Current directory: $(pwd)"

info "Checking Docker versions..."
docker --version
docker buildx version || true
docker compose version

info "Pulling latest code from main..."
git pull origin main

info "Validating Docker Compose configuration..."
docker compose -f "$COMPOSE_FILE" config >/dev/null

info "Rebuilding and starting Docker Compose service..."
docker compose -f "$COMPOSE_FILE" up -d --build

info "Current Docker Compose status:"
docker compose -f "$COMPOSE_FILE" ps

info "Deployment finished."
