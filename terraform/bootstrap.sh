#!/usr/bin/env bash
set -Eeuo pipefail

umask 027

BOOTSTRAP_LOG="/var/log/infra-monitor-bootstrap.log"

PROJECT_DIR="/home/ec2-user/infra-monitor"
HOME_DIR="/home/ec2-user"

RUNTIME_ENV_FILE="$PROJECT_DIR/docker/runtime.env"

GRAFANA_ENV_DIR="$HOME_DIR/.config/infra-monitor"
GRAFANA_ENV_FILE="$GRAFANA_ENV_DIR/grafana.env"

PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

BUILDX_VERSION="v0.36.1"
BUILDX_ASSET="buildx-v0.36.1.linux-amd64"
BUILDX_SHA256="48af8a397ebd60178778bf63611dbcebe5f5e7a9be90eb9147b24b9587455778"

COMPOSE_VERSION="v5.5.0"
COMPOSE_ASSET="docker-compose-linux-x86_64"
COMPOSE_SHA256="c57ab918abd5b05ca7e7d0f275875dd1330a695074f309dc9eab1b49efafcd4b"

S3_BUCKET="${INFRA_BOOTSTRAP_S3_BUCKET:-}"
S3_KEY="${INFRA_BOOTSTRAP_S3_KEY:-system_report.log}"

exec > >(tee -a "$BOOTSTRAP_LOG") 2>&1

fail() {
    echo "ERROR: $1" >&2
    exit 1
}

info() {
    echo "==> $1"
}

trap '
    rc=$?
    echo "ERROR: bootstrap failed near line $LINENO with exit code $rc" >&2
' ERR

info "============================================================"
info "Starting hardened infra-monitor bootstrap"
info "Bootstrap log: $BOOTSTRAP_LOG"

# ------------------------------------------------------------------
# Host packages
# ------------------------------------------------------------------

info "Updating Amazon Linux packages"
dnf update -y

info "Installing required host packages"
dnf install -y \
    git \
    docker \
    coreutils \
    ca-certificates \
    openssl \
    firewalld

if ! command -v curl >/dev/null 2>&1; then
    info "Installing curl-minimal"
    dnf install -y curl-minimal
fi

for command_name in \
    git \
    docker \
    curl \
    openssl \
    sha256sum \
    firewall-cmd
do
    command -v "$command_name" >/dev/null 2>&1 \
        || fail "Required host command missing: $command_name"
done

# ------------------------------------------------------------------
# Host firewall
# ------------------------------------------------------------------

info "Enabling firewalld before Docker"

systemctl enable --now firewalld

firewall-cmd --set-default-zone=public

firewall-cmd \
    --permanent \
    --zone=public \
    --add-service=ssh

for port in 3000 9090 9100; do
    firewall-cmd \
        --permanent \
        --zone=public \
        --remove-port="$port/tcp" \
        >/dev/null 2>&1 \
        || true
done

firewall-cmd --reload

info "Configuring Docker to start after firewalld"

install -d \
    -m 0755 \
    /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/10-firewalld.conf <<'EOF'
[Unit]
Requires=firewalld.service
After=firewalld.service network-online.target
EOF

systemctl daemon-reload

# ------------------------------------------------------------------
# Deterministic Docker CLI plugins
# ------------------------------------------------------------------

info "Preparing system-wide Docker CLI plugin directory"

install -d \
    -m 0755 \
    "$PLUGIN_DIR"

install_pinned_plugin() {
    local name="$1"
    local url="$2"
    local expected_sha256="$3"
    local destination="$4"

    if [ -f "$destination" ] \
        && echo "$expected_sha256  $destination" \
            | sha256sum -c - >/dev/null 2>&1; then

        info "$name already installed with expected checksum"
        chmod 0755 "$destination"
        return
    fi

    info "Installing $name"

    local temp_file
    temp_file="$(mktemp)"

    if ! curl \
        --fail \
        --silent \
        --show-error \
        --location \
        "$url" \
        --output "$temp_file"; then

        rm -f "$temp_file"
        fail "Failed to download $name"
    fi

    if ! echo "$expected_sha256  $temp_file" \
        | sha256sum -c -; then

        rm -f "$temp_file"
        fail "$name checksum verification failed"
    fi

    install \
        -m 0755 \
        "$temp_file" \
        "$destination"

    rm -f "$temp_file"
}

install_pinned_plugin \
    "Docker Buildx $BUILDX_VERSION" \
    "https://github.com/docker/buildx/releases/download/$BUILDX_VERSION/$BUILDX_ASSET" \
    "$BUILDX_SHA256" \
    "$PLUGIN_DIR/docker-buildx"

install_pinned_plugin \
    "Docker Compose $COMPOSE_VERSION" \
    "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/$COMPOSE_ASSET" \
    "$COMPOSE_SHA256" \
    "$PLUGIN_DIR/docker-compose"

# ------------------------------------------------------------------
# Docker
# ------------------------------------------------------------------

info "Starting Docker"

systemctl enable docker

if systemctl is-active --quiet docker; then
    systemctl restart docker
else
    systemctl start docker
fi

usermod -aG docker ec2-user

info "Verifying Docker tooling"

docker --version

docker buildx version \
    | grep -F "$BUILDX_VERSION" \
    || fail "Unexpected Docker Buildx version"

docker compose version \
    | grep -F "$COMPOSE_VERSION" \
    || fail "Unexpected Docker Compose version"

# ------------------------------------------------------------------
# Git checkout
# ------------------------------------------------------------------

info "Checking repository"

[ -d "$PROJECT_DIR/.git" ] \
    || fail "Repository is missing after user-data stage"

if [ -n "$(
    git \
        -C "$PROJECT_DIR" \
        status \
        --porcelain \
        --untracked-files=no
)" ]; then
    fail "Tracked repository files are unexpectedly modified"
fi

info "Repository commit: $(git -C "$PROJECT_DIR" rev-parse --short HEAD)"

# ------------------------------------------------------------------
# Container-readable monitoring configuration
# ------------------------------------------------------------------

info "Preparing container-readable monitoring configuration"

find "$PROJECT_DIR/monitoring/prometheus" \
    -type d \
    -exec chmod 0755 {} +

find "$PROJECT_DIR/monitoring/prometheus" \
    -type f \
    -exec chmod 0644 {} +

find "$PROJECT_DIR/monitoring/grafana" \
    -type d \
    -exec chmod 0755 {} +

find "$PROJECT_DIR/monitoring/grafana" \
    -type f \
    -exec chmod 0644 {} +

# ------------------------------------------------------------------
# Runtime files
# ------------------------------------------------------------------

info "Preparing log directory"

install -d \
    -m 0755 \
    -o root \
    -g root \
    "$PROJECT_DIR/logs"

info "Preparing runtime environment"

if [ ! -f "$RUNTIME_ENV_FILE" ]; then
    [ -f "$PROJECT_DIR/docker/runtime.env.example" ] \
        || fail "Runtime environment example not found"

    install \
        -m 0600 \
        -o ec2-user \
        -g ec2-user \
        "$PROJECT_DIR/docker/runtime.env.example" \
        "$RUNTIME_ENV_FILE"
fi

upsert_env() {
    local key="$1"
    local value="$2"
    local file="$3"

    local temp_file
    temp_file="$(mktemp)"

    grep -v "^${key}=" "$file" \
        > "$temp_file" \
        || true

    printf '%s=%s\n' \
        "$key" \
        "$value" \
        >> "$temp_file"

    cat "$temp_file" > "$file"

    rm -f "$temp_file"
}

upsert_env \
    "INFRA_MONITOR_HOST_ROOT" \
    "/host" \
    "$RUNTIME_ENV_FILE"

upsert_env \
    "INFRA_MONITOR_S3_BUCKET" \
    "$S3_BUCKET" \
    "$RUNTIME_ENV_FILE"

upsert_env \
    "INFRA_MONITOR_S3_KEY" \
    "$S3_KEY" \
    "$RUNTIME_ENV_FILE"

chown ec2-user:ec2-user "$RUNTIME_ENV_FILE"
chmod 0600 "$RUNTIME_ENV_FILE"

# ------------------------------------------------------------------
# Grafana credentials
# ------------------------------------------------------------------

info "Preparing Grafana credential directory"

install -d \
    -m 0700 \
    -o ec2-user \
    -g ec2-user \
    "$GRAFANA_ENV_DIR"

if [ ! -f "$GRAFANA_ENV_FILE" ]; then
    info "Generating initial Grafana administrator password"

    GRAFANA_ADMIN_PASSWORD="$(
        openssl rand -hex 24
    )"

    {
        echo "GF_SECURITY_ADMIN_USER=admin"

        printf \
            'GF_SECURITY_ADMIN_PASSWORD=%s\n' \
            "$GRAFANA_ADMIN_PASSWORD"
    } > "$GRAFANA_ENV_FILE"

    unset GRAFANA_ADMIN_PASSWORD
fi

chown ec2-user:ec2-user "$GRAFANA_ENV_FILE"
chmod 0600 "$GRAFANA_ENV_FILE"

# ------------------------------------------------------------------
# Docker as ec2-user
# ------------------------------------------------------------------

info "Verifying Docker access as ec2-user"

runuser \
    -l ec2-user \
    -c "docker info >/dev/null"

runuser \
    -l ec2-user \
    -c "docker buildx version"

runuser \
    -l ec2-user \
    -c "docker compose version"

# ------------------------------------------------------------------
# Compose validation and deployment
# ------------------------------------------------------------------

info "Validating Docker Compose"

runuser \
    -l ec2-user \
    -c "cd $PROJECT_DIR && docker compose -f docker/docker-compose.yml config --quiet"

info "Deploying infra-monitor stack"

runuser \
    -l ec2-user \
    -c "cd $PROJECT_DIR && bash scripts/deploy-infra-monitor.sh"

# ------------------------------------------------------------------
# IAM / IMDS verification
# ------------------------------------------------------------------

info "Verifying EC2 IAM role access from Infra Monitor container"

runuser \
    -l ec2-user \
    -c "cd $PROJECT_DIR && docker compose -f docker/docker-compose.yml run --rm --entrypoint sh infra-monitor -c 'aws sts get-caller-identity >/dev/null'"

# ------------------------------------------------------------------
# Firewall verification after Docker startup
# ------------------------------------------------------------------

info "Verifying firewalld after Docker startup"

systemctl is-active --quiet firewalld \
    || fail "firewalld is not active"

firewall-cmd \
    --zone=public \
    --query-service=ssh \
    >/dev/null \
    || fail "SSH service is not allowed in public firewalld zone"

for port in 3000 9090 9100; do
    if firewall-cmd \
        --zone=public \
        --query-port="$port/tcp" \
        >/dev/null; then

        fail "Monitoring port unexpectedly open in public zone: $port"
    fi
done

info "Active firewall zones:"
firewall-cmd --get-active-zones

info "Public firewall configuration:"
firewall-cmd \
    --zone=public \
    --list-all

# ------------------------------------------------------------------
# Final monitoring health
# ------------------------------------------------------------------

info "Running final monitoring health check"

runuser \
    -l ec2-user \
    -c "cd $PROJECT_DIR && bash scripts/monitoring_health_check.sh"

touch /var/log/infra-monitor-bootstrap.done

info "Bootstrap completed successfully"
info "============================================================"
