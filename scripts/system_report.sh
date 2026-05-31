#!/bin/bash

set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ===== System Health Report =====

# ===== infra-monitor configuration =====

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load project environment variables if available
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

# Colours
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
    if [ "$1" -ge "$2" ]; then
        echo -e "${RED}⚠ $3: $1%${RESET}"
        echo "⚠ $3: $1%" >> "$LOG_FILE"
    else
        echo -e "${GREEN}✔ $3 OK: $1%${RESET}"
        echo "✔ $3 OK: $1%" >> "$LOG_FILE"
    fi
}

echo -e "${CYAN}${BOLD}SYSTEM HEALTH REPORT${RESET}"
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)"
echo

# Timestamp header in log file
echo "===== $(date) =====" >> "$LOG_FILE"
echo "Hostname: $(hostname)" >> "$LOG_FILE"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)" >> "$LOG_FILE"

# ----------------------------
# CPU Info
# ----------------------------
print_section "CPU Info"
echo "Model: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')"
echo "Cores: $(nproc)"
echo "Model: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')" >> "$LOG_FILE"
echo "Cores: $(nproc)" >> "$LOG_FILE"

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
status_message "$USED_MEM" "$MEMORY_THRESHOLD" "Memory usage"

# ----------------------------
# Disk
# ----------------------------
print_section "Disk Usage (/)"
df -h /
df -h / >> "$LOG_FILE"
USED_DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
status_message "$USED_DISK" "$DISK_THRESHOLD" "Disk usage"

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
echo "" >> "$LOG_FILE"

# Upload log to S3 if a bucket is configured
if [ -n "$S3_BUCKET" ]; then
    if ! aws s3 cp "$LOG_FILE" "s3://$S3_BUCKET/$S3_KEY"; then
        echo "S3 upload failed at $(date)" >> "$ERROR_LOG"
    fi
else
    echo "S3 upload skipped at $(date): INFRA_MONITOR_S3_BUCKET not set" >> "$ERROR_LOG"
fi

FILE_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)

if [ "$FILE_SIZE" -gt "$MAX_SIZE" ]; then
    mv "$LOG_FILE" "$LOG_DIR/system_report_$(date +%F_%H-%M-%S).log"
    touch "$LOG_FILE"
fi


