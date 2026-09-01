#!/bin/bash

set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ===== System Health Report =====
# ===== infra-monitor configuration =====

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$HOME/.infra-monitor.env" ]; then
    source "$HOME/.infra-monitor.env"
fi

INFRA_MONITOR_HOME="${INFRA_MONITOR_HOME:-$BASE_DIR}"
LOG_DIR="${INFRA_MONITOR_LOG_DIR:-$INFRA_MONITOR_HOME/logs}"
LOG_FILE="${INFRA_MONITOR_SYSTEM_LOG:-$LOG_DIR/system_report.log}"
ERROR_LOG="${INFRA_MONITOR_ERROR_LOG:-$LOG_DIR/error.log}"

CPU_THRESHOLD="${INFRA_MONITOR_CPU_THRESHOLD:-80}"
MEMORY_THRESHOLD="${INFRA_MONITOR_MEMORY_THRESHOLD:-80}"
DISK_THRESHOLD="${INFRA_MONITOR_DISK_THRESHOLD:-85}"
MAX_SIZE="${INFRA_MONITOR_MAX_LOG_SIZE:-50000}"

S3_BUCKET="${INFRA_MONITOR_S3_BUCKET:-}"
S3_KEY="${INFRA_MONITOR_S3_KEY:-system_report.log}"

METRICS_DIR="${INFRA_MONITOR_METRICS_DIR:-/app/metrics}"
METRICS_FILE="$METRICS_DIR/infra_monitor.prom"
HOST_ROOT="${INFRA_MONITOR_HOST_ROOT:-/host}"

CPU_WARNING=0
MEMORY_WARNING=0
DISK_WARNING=0
OVERALL_WARNING=0
REPORT_SUCCESS=0
LAST_SUCCESS_TIMESTAMP=0

if [ -f "$METRICS_FILE" ]; then
    LAST_SUCCESS_TIMESTAMP="$(
        awk '
            $1 == "infra_monitor_last_success_timestamp_seconds" {
                print $2
            }
        ' "$METRICS_FILE" 2>/dev/null \
        | tail -n 1
    )"

    if ! [[ "$LAST_SUCCESS_TIMESTAMP" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        LAST_SUCCESS_TIMESTAMP=0
    fi
fi

mkdir -p "$LOG_DIR"

HOSTNAME="$(hostname)"
CPU_STATUS="UNKNOWN"
MEMORY_STATUS="UNKNOWN"
DISK_STATUS="UNKNOWN"
OVERALL_STATUS="OK"
if [ -n "$S3_BUCKET" ]; then
    S3_DESTINATION="s3://$S3_BUCKET/$S3_KEY"
else
    S3_DESTINATION="Disabled"
fi


write_prometheus_metrics() {
    mkdir -p "$METRICS_DIR"

    local temp_file
    local current_timestamp

    temp_file="${METRICS_FILE}.$$"
    current_timestamp="$(date +%s)"

    if [ "$CPU_WARNING" -eq 1 ] \
        || [ "$MEMORY_WARNING" -eq 1 ] \
        || [ "$DISK_WARNING" -eq 1 ]; then
        OVERALL_WARNING=1
    else
        OVERALL_WARNING=0
    fi

    cat > "$temp_file" <<EOF
# HELP infra_monitor_last_run_timestamp_seconds Unix timestamp of the latest Infra Monitor execution.
# TYPE infra_monitor_last_run_timestamp_seconds gauge
infra_monitor_last_run_timestamp_seconds $current_timestamp

# HELP infra_monitor_last_success_timestamp_seconds Unix timestamp of the most recent successful Infra Monitor execution.
# TYPE infra_monitor_last_success_timestamp_seconds gauge
infra_monitor_last_success_timestamp_seconds $LAST_SUCCESS_TIMESTAMP

# HELP infra_monitor_cpu_warning Whether CPU usage exceeded the configured threshold.
# TYPE infra_monitor_cpu_warning gauge
infra_monitor_cpu_warning $CPU_WARNING

# HELP infra_monitor_memory_warning Whether memory usage exceeded the configured threshold.
# TYPE infra_monitor_memory_warning gauge
infra_monitor_memory_warning $MEMORY_WARNING

# HELP infra_monitor_disk_warning Whether root filesystem usage exceeded the configured threshold.
# TYPE infra_monitor_disk_warning gauge
infra_monitor_disk_warning $DISK_WARNING

# HELP infra_monitor_overall_warning Whether any monitored resource exceeded its configured threshold.
# TYPE infra_monitor_overall_warning gauge
infra_monitor_overall_warning $OVERALL_WARNING

# HELP infra_monitor_report_success Whether the latest Infra Monitor report completed successfully.
# TYPE infra_monitor_report_success gauge
infra_monitor_report_success $REPORT_SUCCESS
EOF

    mv "$temp_file" "$METRICS_FILE"
}

publish_metrics_on_exit() {
    local exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        REPORT_SUCCESS=1
        LAST_SUCCESS_TIMESTAMP="$(date +%s)"
    else
        REPORT_SUCCESS=0
    fi

    write_prometheus_metrics || true
}

trap publish_metrics_on_exit EXIT

required_commands=(
    awk
    date
    df
    free
    grep
    hostname
    ip
    lscpu
    nproc
    ps
    sed
    stat
    top
    tr
    uptime
)

for command_name in "${required_commands[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 \
        || {
            echo "ERROR: required command not found: $command_name" >&2
            exit 1
        }
done

if [ ! -d "$HOST_ROOT" ]; then
    echo "ERROR: host root is not mounted at: $HOST_ROOT" >&2
    exit 1
fi

if [ -n "$S3_BUCKET" ]; then
    command -v aws >/dev/null 2>&1 \
        || {
            echo "ERROR: AWS CLI is required when S3 upload is enabled" >&2
            exit 1
        }
fi

get_host_os() {
    if [ -r "$HOST_ROOT/etc/os-release" ]; then
        awk -F= '
            $1 == "PRETTY_NAME" {
                value = substr($0, index($0, "=") + 1)
                gsub(/^"|"$/, "", value)
                print value
                exit
            }
        ' "$HOST_ROOT/etc/os-release"
    else
        echo "Unknown"
    fi
}

HOST_OS="$(get_host_os)"

timestamp() {
    date "+%Y-%m-%d %H:%M:%S %Z"
}

log_report_header() {
    {
        echo "=================================================="
        echo "[$(timestamp)] System Health Report"
        echo "Hostname: $HOSTNAME"
        echo "User: $(whoami)"
        echo "Project Directory: $INFRA_MONITOR_HOME"
        echo "Log File: $LOG_FILE"
        echo "=================================================="
    } >> "$LOG_FILE"
}

log_report_footer() {
    {
        echo "=================================================="
        echo ""
    } >> "$LOG_FILE"
}

log_error() {
    echo "[$(timestamp)] ERROR: $1" >> "$ERROR_LOG"
}

log_summary_block() {
    {
        echo "=================================================="
        echo "Timestamp: $(timestamp)"
        echo "Hostname: $HOSTNAME"
        echo "CPU: $CPU_STATUS"
        echo "Memory: $MEMORY_STATUS"
        echo "Disk: $DISK_STATUS"
        echo "Thresholds: CPU=${CPU_THRESHOLD}% Memory=${MEMORY_THRESHOLD}% Disk=${DISK_THRESHOLD}%"
        echo "Status: $OVERALL_STATUS"
        echo "S3 Destination: $S3_DESTINATION"
        echo "=================================================="
        echo ""
    } >> "$LOG_FILE"
}

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

print_section() {
    echo -e "\n${BLUE}${BOLD}$1${RESET}"
    echo -e "\n$1" >> "$LOG_FILE"
}

status_message() {
    local usage="$1"
    local threshold="$2"
    local label="$3"
    local state="OK"
    local warning=0

    if [ "$usage" -gt "$threshold" ]; then
        state="HIGH"
        warning=1
        OVERALL_STATUS="WARN"
    fi

    case "$label" in
        CPU)
            CPU_STATUS="$state (${usage}%/${threshold}%)"
            CPU_WARNING="$warning"
            ;;
        Memory)
            MEMORY_STATUS="$state (${usage}%/${threshold}%)"
            MEMORY_WARNING="$warning"
            ;;
        Disk)
            DISK_STATUS="$state (${usage}%/${threshold}%)"
            DISK_WARNING="$warning"
            ;;
    esac
}

echo -e "${CYAN}${BOLD}SYSTEM HEALTH REPORT${RESET}"
echo "Date: $(date)"
echo "Hostname: $HOSTNAME"
echo "OS: $HOST_OS"
echo

log_report_header
echo "OS: $HOST_OS" >> "$LOG_FILE"

# ----------------------------
# CPU Info
# ----------------------------
print_section "CPU Info"
echo "Model: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')"
echo "Cores: $(nproc)"
echo "Model: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')" >> "$LOG_FILE"
echo "Cores: $(nproc)" >> "$LOG_FILE"

CPU_USAGE=$(top -bn1 | awk '/^%Cpu/ {printf "%.0f", 100 - $8}')
status_message "$CPU_USAGE" "$CPU_THRESHOLD" "CPU"

# ----------------------------
# Uptime & Load
# ----------------------------
print_section "Uptime & Load"
uptime -p
uptime | awk -F'load average:' '{ print "Load Average:" $2 }'
uptime -p >> "$LOG_FILE"
uptime | awk -F'load average:' '{ print "Load Average:" $2 }' >> "$LOG_FILE"

# ----------------------------
# Memory
# ----------------------------
print_section "Memory Usage"
free -h
free -h >> "$LOG_FILE"
USED_MEM=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
status_message \
	"$USED_MEM" \
	"$MEMORY_THRESHOLD" \
	"Memory"

# ----------------------------
# Disk
# ----------------------------
print_section "Disk Usage (Host Root)"

df -h "$HOST_ROOT"
df -h "$HOST_ROOT" >> "$LOG_FILE"

USED_DISK="$(
    df -P "$HOST_ROOT" \
        | awk 'NR==2 {
            gsub("%", "", $5)
            print $5
        }'
)"
status_message \
	"$USED_DISK" \
	"$DISK_THRESHOLD" \
	"Disk"

# ----------------------------
# Top Processes
# ----------------------------
print_section "Top Memory Processes"
ps -eo pid,user,%mem,%cpu,comm --sort=-%mem | head -n 6
ps -eo pid,user,%mem,%cpu,comm --sort=-%mem | head -n 6 >> "$LOG_FILE"

# ----------------------------
# Network
# ----------------------------
print_section "Network Interfaces"
ip -brief addr show | grep UP || true
ip -brief addr show | grep UP >> "$LOG_FILE" || true

# Complete the report before attempting any upload.
log_summary_block

echo -e "\n${CYAN}${BOLD}Report complete.${RESET}"

if [ -n "$S3_BUCKET" ]; then
    if aws s3 cp "$LOG_FILE" "$S3_DESTINATION"; then
        echo -e "${GREEN}S3 upload succeeded: $S3_DESTINATION${RESET}"
    else
        echo -e "${RED}S3 upload failed: $S3_DESTINATION${RESET}" >&2
        log_error "S3 upload failed for $LOG_FILE to $S3_DESTINATION"
    fi
else
    echo "S3 upload skipped: INFRA_MONITOR_S3_BUCKET is not set"
fi

rotate_log_file() {
    local file="$1"
    local label="$2"
    local size_limit="${3:-$MAX_SIZE}"

    if [ ! -f "$file" ]; then
        return 0
    fi

    local file_size
    file_size=$(stat -c%s "$file" 2>/dev/null || echo 0)

    if [ "$file_size" -gt "$size_limit" ]; then
        local dir
        local base
        local stem
        local archive

        dir="$(dirname "$file")"
        base="$(basename "$file")"
        stem="${base%.*}"
        archive="$dir/${stem}_$(date +%F_%H-%M-%S).log"

        mv "$file" "$archive"
        touch "$file"

        echo "[$(timestamp)] Rotated $label log: $archive" >> "$file"
    fi
}

rotate_log_file "$LOG_FILE" "system report" "$MAX_SIZE"
rotate_log_file "$ERROR_LOG" "error" "$MAX_SIZE"

