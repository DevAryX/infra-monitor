#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_LOG="/var/log/infra-monitor-bootstrap.log"
PROJECT_DIR="/home/ec2-user/infra-monitor"
REPO_URL="https://github.com/DevAryX/infra-monitor.git"
HOME_DIR="/home/ec2-user"
PLUGIN_DIR="$HOME_DIR/.docker/cli-plugins"
ENV_FILE="$PROJECT_DIR/docker/day9.env"

exec > >(tee -a "$BOOTSTRAP_LOG") 2>&1

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

info() {
  echo "==> $1"
}

info "Starting infra-monitor EC2 bootstrap"

info "Updating packages and installing base tools"
dnf update -y
dnf install -y git docker curl ca-certificates

info "Starting and enabling Docker"
systemctl enable --now docker

info "Adding ec2-user to docker group"
usermod -aG docker ec2-user

info "Preparing Docker CLI plugin directory"
mkdir -p "$PLUGIN_DIR"

case "$(uname -m)" in
  x86_64)
    BUILDX_ARCH="amd64"
    COMPOSE_ARCH="x86_64"
    ;;
  aarch64)
    BUILDX_ARCH="arm64"
    COMPOSE_ARCH="aarch64"
    ;;
  *)
    fail "Unsupported architecture: $(uname -m)"
    ;;
esac

info "Installing or updating Docker Buildx"
BUILDX_VERSION="$(curl -fsSL https://api.github.com/repos/docker/buildx/releases/latest | grep '"tag_name":' | head -n1 | cut -d '"' -f4)"
[ -n "$BUILDX_VERSION" ] || fail "Could not detect latest Docker Buildx version"

curl -fsSL \
  "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${BUILDX_ARCH}" \
  -o "$PLUGIN_DIR/docker-buildx"

chmod +x "$PLUGIN_DIR/docker-buildx"

info "Installing or updating Docker Compose plugin"
COMPOSE_VERSION="$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | head -n1 | cut -d '"' -f4)"
[ -n "$COMPOSE_VERSION" ] || fail "Could not detect latest Docker Compose version"

curl -fsSL \
  "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}" \
  -o "$PLUGIN_DIR/docker-compose"

chmod +x "$PLUGIN_DIR/docker-compose"

info "Cloning infra-monitor repository"
if [ ! -d "$PROJECT_DIR/.git" ]; then
  rm -rf "$PROJECT_DIR"
  git clone "$REPO_URL" "$PROJECT_DIR"
else
  git -C "$PROJECT_DIR" pull origin main
fi

info "Creating logs directory"
mkdir -p "$PROJECT_DIR/logs"

info "Creating default Docker env file if missing"
if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" <<'ENVEOF'
CPU_THRESHOLD=70
MEMORY_THRESHOLD=70
DISK_THRESHOLD=70
INFRA_MONITOR_SYSTEM_LOG=/app/logs/day9-env-file.log
INFRA_MONITOR_ERROR_LOG=/app/logs/day9-error.log
ENVEOF
fi

info "Preparing deployment script"
if [ -f "$PROJECT_DIR/scripts/deploy-infra-monitor.sh" ]; then
  cp "$PROJECT_DIR/scripts/deploy-infra-monitor.sh" "$HOME_DIR/deploy-infra-monitor.sh"
else
  fail "Repo deploy script not found at $PROJECT_DIR/scripts/deploy-infra-monitor.sh"
fi

chmod +x "$HOME_DIR/deploy-infra-monitor.sh"
chmod +x "$PROJECT_DIR/scripts/"*.sh || true

info "Fixing ownership and permissions"
chown -R ec2-user:ec2-user "$PROJECT_DIR"
chown -R ec2-user:ec2-user "$HOME_DIR/.docker"
chown ec2-user:ec2-user "$HOME_DIR/deploy-infra-monitor.sh"

chmod -R u+rwX "$PROJECT_DIR/logs"

info "Verifying Docker as ec2-user"
runuser -l ec2-user -c "docker --version"
runuser -l ec2-user -c "docker buildx version"
runuser -l ec2-user -c "docker compose version"
runuser -l ec2-user -c "docker info >/dev/null"

info "Validating Docker Compose config"
runuser -l ec2-user -c "docker compose -f /home/ec2-user/infra-monitor/docker/docker-compose.yml config >/dev/null"

info "Bootstrap completed successfully"
touch /var/log/infra-monitor-bootstrap.done
