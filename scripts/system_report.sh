#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


# ===== System Health Report =====

# Log file
LOG_FILE="/home/ec2-user/infra-monitor/logs/system_report.log"

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

clear
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
status_message "$USED_MEM" 80 "Memory usage"

# ----------------------------
# Disk
# ----------------------------
print_section "Disk Usage (/)"
df -h /
df -h / >> "$LOG_FILE"
USED_DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
status_message "$USED_DISK" 85 "Disk usage"

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
ip -brief addr show | grep UP
ip -brief addr show | grep UP >> "$LOG_FILE"

echo -e "\n${CYAN}${BOLD}Report complete.${RESET}"
echo "" >> "$LOG_FILE"
aws s3 cp $LOG_FILE s3://infra-monitor-ary-logs-2026-314146300600-eu-west-2-an/system_report.log
