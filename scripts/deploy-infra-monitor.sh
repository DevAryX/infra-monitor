#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$HOME/infra-monitor"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
RUNTIME_ENV_FILE="$PROJECT_DIR/docker/runtime.env"
GRAFANA_ENV_FILE="$HOME/.config/infra-monitor/grafana.env"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/deploy.log"

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

info() {
  echo "==> $1"
}

[ -d "$PROJECT_DIR" ] || fail "Project directory not found: $PROJECT_DIR"

mkdir -p "$LOG_DIR"

exec > >(awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush(); }' | tee -a "$LOG_FILE") 2>&1

info "============================================================"
info "Starting infra-monitor deployment"
info "Log file: $LOG_FILE"

[ -d "$PROJECT_DIR/.git" ] || fail "Project directory exists but is not a Git repository: $PROJECT_DIR"

command -v git >/dev/null 2>&1 || fail "Git is not installed"
command -v docker >/dev/null 2>&1 || fail "Docker is not installed"

docker info >/dev/null 2>&1 || fail "Docker daemon is not running or current user cannot access Docker"
docker compose version >/dev/null 2>&1 || fail "Docker Compose plugin is not available"

[ -f "$COMPOSE_FILE" ] || fail "Docker Compose file not found: $COMPOSE_FILE"

[ -f "$RUNTIME_ENV_FILE" ] \
  || fail "Runtime env file not found: $RUNTIME_ENV_FILE"

[ -f "$GRAFANA_ENV_FILE" ] \
  || fail "Grafana env file not found: $GRAFANA_ENV_FILE"

case "$(stat -c '%a' "$RUNTIME_ENV_FILE")" in
  600|400) ;;
  *)
    fail "Runtime env file must use permission 600 or 400: $RUNTIME_ENV_FILE"
    ;;
esac

case "$(stat -c '%a' "$GRAFANA_ENV_FILE")" in
  600|400) ;;
  *)
    fail "Grafana env file must use permission 600 or 400: $GRAFANA_ENV_FILE"
    ;;
esac

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

info "Deployment finished successfully"
info "============================================================"
