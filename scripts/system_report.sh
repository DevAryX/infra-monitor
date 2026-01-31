#!/bin/bash

# ===== System Health Report =====

# Colours
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

print_section() {
    echo -e "\n${BLUE}${BOLD}$1${RESET}"
}

status_message() {
    if [ "$1" -ge "$2" ]; then
        echo -e "${RED}⚠ $3: $1%${RESET}"
    else
        echo -e "${GREEN}✔ $3 OK: $1%${RESET}"
    fi
}

clear

echo -e "${CYAN}${BOLD}SYSTEM STATUS REPORT${RESET}"
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)"
echo

# ----------------------------
# CPU Info
# ----------------------------
print_section "CPU Info"
echo "Model: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')"
echo "Cores: $(nproc)"

# ----------------------------
# Uptime & Load
# ----------------------------
print_section "Uptime & Load"
uptime -p
uptime | awk -F'load average:' '{ print "Load Average:" $2 }'

# ----------------------------
# Memory
# ----------------------------
print_section "Memory Usage"
free -h

USED_MEM=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
status_message "$USED_MEM" 80 "Memory usage"

# ----------------------------
# Disk
# ----------------------------
print_section "Disk Usage (/)"
df -h /

USED_DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
status_message "$USED_DISK" 85 "Disk usage"

# ----------------------------
# Top Processes
# ----------------------------
print_section "Top Memory Processes"
ps -eo pid,user,%mem,%cpu,comm --sort=-%mem | head -n 6

# ----------------------------
# Network
# ----------------------------
print_section "Network Interfaces"
ip -brief addr show | grep UP

echo -e "\n${CYAN}${BOLD}Report complete.${RESET}"

