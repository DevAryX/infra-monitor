#!/bin/bash

# ==========================================
# resource_check.sh
# Lightweight system resource checker
# ==========================================

THRESHOLD_CPU=75
THRESHOLD_MEM=80

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
MEM_USAGE=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')

echo "CPU Usage: ${CPU_USAGE}%"
echo "Memory Usage: ${MEM_USAGE}%"

if [ "$CPU_USAGE" -ge "$THRESHOLD_CPU" ]; then
    echo "High CPU usage detected"
fi

if [ "$MEM_USAGE" -ge "$THRESHOLD_MEM" ]; then
    echo "High memory usage detected"
fi

