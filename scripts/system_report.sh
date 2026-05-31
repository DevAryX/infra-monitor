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

mkdir -p "$LOG_DIR"

HOSTNAME="$(hostname)"
CPU_STATUS="UNKNOWN"
MEMORY_STATUS="UNKNOWN"
DISK_STATUS="UNKNOWN"
OVERALL_STATUS="OK"
S3_UPLOAD_RESULT="NOT RUN"

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
        echo "S3 Upload: $S3_UPLOAD_RESULT"
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

    if [ "$usage" -gt "$threshold" ]; then
        state="HIGH"
        OVERALL_STATUS="WARN"
    fi

    case "$label" in
        CPU)
            CPU_STATUS="$state (${usage}%/${threshold}%)"
            ;;
        Memory)
            MEMORY_STATUS="$state (${usage}%/${threshold}%)"
            ;;
        Disk)
            DISK_STATUS="$state (${usage}%/${threshold}%)"
            ;;
    esac
}

echo -e "${CYAN}${BOLD}SYSTEM HEALTH REPORT${RESET}"
echo "Date: $(date)"
echo "Hostname: $HOSTNAME"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)"
echo

log_report_header
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)" >> "$LOG_FILE"

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
status_message "$USED_MEM" "$MEMORY_THRESHOLD" "Memory"

# ----------------------------
# Disk
# ----------------------------
print_section "Disk Usage (/)"
df -h /
df -h / >> "$LOG_FILE"
USED_DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
status_message "$USED_DISK" "$DISK_THRESHOLD" "Disk"

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

echo -e "\n${CYAN}${BOLD}Report complete.${RESET}"

if [ -n "$S3_BUCKET" ]; then
    if aws s3 cp "$LOG_FILE" "s3://$S3_BUCKET/$S3_KEY"; then
        S3_UPLOAD_RESULT="Success -> s3://$S3_BUCKET/$S3_KEY"
    else
        S3_UPLOAD_RESULT="Failed"
        log_error "S3 upload failed for $LOG_FILE to s3://$S3_BUCKET/$S3_KEY"
    fi
else
    S3_UPLOAD_RESULT="Skipped - INFRA_MONITOR_S3_BUCKET not set"
    log_error "S3 upload skipped because INFRA_MONITOR_S3_BUCKET is not set"
fi

log_summary_block

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

