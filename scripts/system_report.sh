#!/bin/bash

# ==========================================
# system_report.sh
# Advanced System Health Report
# ==========================================

# Colours
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

clear

echo -e "${BOLD}${CYAN}=============================="
echo -e "     SYSTEM HEALTH REPORT"
echo -e "==============================${RESET}\n"

echo -e "${BOLD}Date:${RESET} $(date)"
echo -e "${BOLD}Hostname:${RESET} $(hostname)"
echo -e "${BOLD}OS:${RESET} $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)"
echo

# ----------------------------
# Uptime & Load
# ----------------------------
echo -e "${BLUE}${BOLD}Uptime & Load${RESET}"
uptime -p
uptime | awk -F'load average:' '{ print "Load Average:" $2 }'
echo

# ----------------------------
# CPU Info
# ----------------------------
echo -e "${BLUE}${BOLD}CPU${RESET}"
echo "Model: $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')"
echo "Cores: $(nproc)"
echo

# ----------------------------
# Memory Usage
# ----------------------------
echo -e "${BLUE}${BOLD}Memory Usage${RESET}"
free -h

USED_MEM=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
if [ "$USED_MEM" -ge 80 ]; then
    echo -e "${RED}⚠ High memory usage: ${USED_MEM}%${RESET}"
else
    echo -e "${GREEN}✔ Memory usage normal: ${USED_MEM}%${RESET}"
fi
echo

# ----------------------------
# Disk Usage
# ----------------------------
echo -e "${BLUE}${BOLD}Disk Usage (/ root)${RESET}"
df -h /

USED_DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$USED_DISK" -ge 85 ]; then
    echo -e "${RED}⚠ Disk usage critical: ${USED_DISK}%${RESET}"
else
    echo -e "${GREEN}✔ Disk usage OK: ${USED_DISK}%${RESET}"
fi
echo

# ----------------------------
# Top Processes
# ----------------------------
echo -e "${BLUE}${BOLD}Top 5 Memory-Consuming Processes${RESET}"
ps -eo pid,user,%mem,%cpu,comm --sort=-%mem | head -n 6
echo

# ----------------------------
# Network
# ----------------------------
echo -e "${BLUE}${BOLD}Network${RESET}"
ip -brief addr show | grep UP
echo

# ----------------------------
# Summary
# ----------------------------
echo -e "${CYAN}${BOLD}Report Complete.${RESET}"
