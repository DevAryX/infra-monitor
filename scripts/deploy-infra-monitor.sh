#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$HOME/infra-monitor"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
RUNTIME_ENV_FILE="$PROJECT_DIR/docker/runtime.env"
GRAFANA_ENV_FILE="$HOME/.config/infra-monitor/grafana.env"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/deploy.log"
HEALTH_CHECK_SCRIPT="$PROJECT_DIR/scripts/monitoring_health_check.sh"

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

info "Refreshing origin/main reference..."
git fetch --quiet origin main

info "Verifying deployment checkout..."

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  fail "Tracked files contain local changes; deployment checkout must be clean"
fi

CURRENT_COMMIT="$(git rev-parse HEAD)"
ORIGIN_COMMIT="$(git rev-parse origin/main)"

if [ "$CURRENT_COMMIT" != "$ORIGIN_COMMIT" ]; then
  fail "Deployment checkout is not synchronised with origin/main"
fi

info "Deployment checkout is clean"
info "Deploying commit: $(git rev-parse --short HEAD)"

[ -f "$HEALTH_CHECK_SCRIPT" ] \
  || fail "Monitoring health-check script not found: $HEALTH_CHECK_SCRIPT"

info "Validating Docker Compose configuration..."
docker compose -f "$COMPOSE_FILE" config --quiet

info "Rebuilding and starting Docker Compose stack..."
docker compose \
  -f "$COMPOSE_FILE" \
  up -d --build

info "Current Docker Compose status:"
docker compose \
  -f "$COMPOSE_FILE" \
  ps -a

info "Running monitoring post-deployment health checks..."

if ! bash "$HEALTH_CHECK_SCRIPT"; then
  info "Monitoring health checks failed"
  info "Collecting diagnostic information..."

  docker compose \
    -f "$COMPOSE_FILE" \
    ps -a \
    || true

  printf '\n=== NODE EXPORTER LOGS ===\n'
  docker logs \
    --tail 100 \
    node-exporter \
    || true

  printf '\n=== PROMETHEUS LOGS ===\n'
  docker logs \
    --tail 100 \
    prometheus \
    || true

  printf '\n=== GRAFANA LOGS ===\n'
  docker logs \
    --tail 100 \
    grafana \
    || true

  printf '\n=== INFRA MONITOR LOGS ===\n'
  docker logs \
    --tail 100 \
    infra-monitor-compose \
    || true

  fail "Deployment completed but monitoring health checks failed"
fi

info "Monitoring stack verified successfully"
info "Deployment finished successfully"
info "============================================================"
