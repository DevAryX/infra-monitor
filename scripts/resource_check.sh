#!/bin/bash

# ==========================================
# resource_check.sh
# Lightweight system resource checker
# ==========================================

set -euo pipefail

if [ -f "$HOME/.infra-monitor.env" ]; then
    source "$HOME/.infra-monitor.env"
fi

THRESHOLD_CPU="${INFRA_MONITOR_CPU_THRESHOLD:-80}"
THRESHOLD_MEM="${INFRA_MONITOR_MEMORY_THRESHOLD:-80}"

CPU_USAGE="$(
    LC_ALL=C top -bn1 \
        | awk '/Cpu\(s\)/ {
            printf "%.0f", 100 - $8
            exit
        }'
)"

MEM_USAGE="$(
    free \
        | awk '/Mem:/ {
            printf "%.0f", $3 / $2 * 100
        }'
)"

if ! [[ "$CPU_USAGE" =~ ^[0-9]+$ ]]; then
    echo "ERROR: unable to determine CPU usage" >&2
    exit 1
fi

if ! [[ "$MEM_USAGE" =~ ^[0-9]+$ ]]; then
    echo "ERROR: unable to determine memory usage" >&2
    exit 1
fi

echo "CPU Usage: ${CPU_USAGE}%"
echo "Memory Usage: ${MEM_USAGE}%"

if [ "$CPU_USAGE" -ge "$THRESHOLD_CPU" ]; then
    echo "High CPU usage detected"
fi

if [ "$MEM_USAGE" -ge "$THRESHOLD_MEM" ]; then
    echo "High memory usage detected"
fi

