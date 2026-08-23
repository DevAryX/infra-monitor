#!/usr/bin/env bash
set -euo pipefail

NODE_EXPORTER_URL="${NODE_EXPORTER_URL:-http://127.0.0.1:9100}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://127.0.0.1:9090}"
GRAFANA_URL="${GRAFANA_URL:-http://127.0.0.1:3000}"

RETRIES="${MONITORING_HEALTH_RETRIES:-30}"
DELAY_SECONDS="${MONITORING_HEALTH_DELAY_SECONDS:-2}"

INFRA_MONITOR_CONTAINER="${INFRA_MONITOR_CONTAINER:-infra-monitor-compose}"

info() {
    printf '==> %s\n' "$1"
}

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

command -v curl >/dev/null 2>&1 \
    || fail "curl is required"

command -v docker >/dev/null 2>&1 \
    || fail "docker is required"

wait_for_http() {
    local name="$1"
    local url="$2"
    local attempt

    for ((attempt = 1; attempt <= RETRIES; attempt++)); do
        if curl --fail --silent --show-error \
            "$url" \
            >/dev/null 2>&1; then
            info "$name is reachable"
            return 0
        fi

        printf 'Waiting for %s (%d/%d)...\n' \
            "$name" \
            "$attempt" \
            "$RETRIES"

        sleep "$DELAY_SECONDS"
    done

    fail "$name did not become reachable: $url"
}

wait_for_infra_monitor() {
    local attempt
    local status
    local exit_code

    for ((attempt = 1; attempt <= RETRIES; attempt++)); do
        if ! docker inspect \
            "$INFRA_MONITOR_CONTAINER" \
            >/dev/null 2>&1; then

            printf 'Waiting for Infra Monitor container (%d/%d)...\n' \
                "$attempt" \
                "$RETRIES"

            sleep "$DELAY_SECONDS"
            continue
        fi

        status="$(
            docker inspect \
                --format '{{.State.Status}}' \
                "$INFRA_MONITOR_CONTAINER"
        )"

        exit_code="$(
            docker inspect \
                --format '{{.State.ExitCode}}' \
                "$INFRA_MONITOR_CONTAINER"
        )"

        case "$status" in
            exited)
                if [ "$exit_code" -eq 0 ]; then
                    info "Infra Monitor completed successfully"
                    return 0
                fi

                fail \
                    "Infra Monitor exited with code $exit_code"
                ;;

            running|created|restarting)
                printf 'Waiting for Infra Monitor to complete (%d/%d)...\n' \
                    "$attempt" \
                    "$RETRIES"

                sleep "$DELAY_SECONDS"
                ;;

            *)
                fail \
                    "Unexpected Infra Monitor state: $status"
                ;;
        esac
    done

    fail "Infra Monitor did not complete within the health-check window"
}

wait_for_prometheus_value_one() {
    local label="$1"
    local query="$2"
    local attempt
    local response=""

    for ((attempt = 1; attempt <= RETRIES; attempt++)); do
        response="$(
            curl \
                --fail \
                --silent \
                --show-error \
                --get \
                --data-urlencode "query=$query" \
                "$PROMETHEUS_URL/api/v1/query" \
                2>/dev/null \
                || true
        )"

        if grep -Eq \
            '"value":\[[^]]*,"1"\]' \
            <<< "$response"; then

            info "$label returned 1"
            return 0
        fi

        printf 'Waiting for Prometheus query: %s (%d/%d)...\n' \
            "$label" \
            "$attempt" \
            "$RETRIES"

        sleep "$DELAY_SECONDS"
    done

    printf '%s\n' "$response" >&2

    fail \
        "Prometheus query did not return the expected value: $label"
}

info "Starting monitoring health checks"

wait_for_infra_monitor

wait_for_http \
    "Node Exporter" \
    "$NODE_EXPORTER_URL/metrics"

wait_for_http \
    "Prometheus" \
    "$PROMETHEUS_URL/-/ready"

wait_for_http \
    "Grafana" \
    "$GRAFANA_URL/api/health"

info "Validating Prometheus configuration"

docker exec prometheus \
    promtool check config \
    /etc/prometheus/prometheus.yml \
    >/dev/null

info "Checking Prometheus health with promtool"

docker exec prometheus \
    promtool check healthy \
    --url=http://localhost:9090 \
    >/dev/null

docker exec prometheus \
    promtool check ready \
    --url=http://localhost:9090 \
    >/dev/null

info "Checking Node Exporter textfile collector"

NODE_METRICS="$(
    curl --fail --silent --show-error \
        "$NODE_EXPORTER_URL/metrics"
)"

grep -Eq \
    '^node_textfile_scrape_error 0(\.0+)?$' \
    <<< "$NODE_METRICS" \
    || fail "Node Exporter textfile collector reports an error"

for metric in \
    infra_monitor_last_run_timestamp_seconds \
    infra_monitor_last_success_timestamp_seconds \
    infra_monitor_cpu_warning \
    infra_monitor_memory_warning \
    infra_monitor_disk_warning \
    infra_monitor_overall_warning \
    infra_monitor_report_success
do
    grep -Eq \
        "^${metric}([ {]|$)" \
        <<< "$NODE_METRICS" \
        || fail "Custom metric missing from Node Exporter: $metric"
done

grep -Eq \
    '^infra_monitor_report_success 1(\.0+)?$' \
    <<< "$NODE_METRICS" \
    || fail "Latest Infra Monitor report was not successful"

info "Validating generated Prometheus exposition"

docker exec node-exporter \
    cat /var/lib/node_exporter/textfile_collector/infra_monitor.prom \
    | docker exec -i prometheus \
        promtool check metrics \
        >/dev/null

wait_for_prometheus_value_one \
    "Prometheus self target" \
    'up{job="prometheus"}'

wait_for_prometheus_value_one \
    "Node Exporter target" \
    'up{job="node-exporter"}'

wait_for_prometheus_value_one \
    "Infra Monitor report status" \
    'infra_monitor_report_success{job="node-exporter"}'

info "Checking Grafana database health"

GRAFANA_HEALTH="$(
    curl --fail --silent --show-error \
        "$GRAFANA_URL/api/health"
)"

grep -Eq \
    '"database"[[:space:]]*:[[:space:]]*"ok"' \
    <<< "$GRAFANA_HEALTH" \
    || fail "Grafana database health is not OK"

info "============================================================"
info "All monitoring health checks passed"
info "Infra Monitor: success"
info "Node Exporter: healthy"
info "Textfile collector: healthy"
info "Prometheus: healthy and ready"
info "Prometheus targets: UP"
info "Custom metrics: ingested"
info "Grafana: healthy"
info "============================================================"
