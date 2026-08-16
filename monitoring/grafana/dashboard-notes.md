# Grafana Dashboard

## Dashboard

The main dashboard is named:

```
Infra Monitor — EC2 Overview
```

So Right now, I am testing it locally on my Ubuntu VM before moving the monitoring stack onto EC2.

Grafana uses Prometheus as the data source.

Prometheus gets the metrics from Node Exporter.

Simple flow:

```
Node Exporter
↓
Prometheus
↓
Grafana dashboard
```

## Panels

Current dashboard panels:

```
CPU Utilisation      → Gauge
Memory Utilisation   → Gauge
Root Disk Usage      → Gauge
Target Status        → Stat
Network Received     → Time series
Network Transmitted  → Time series
Available Memory     → Stat
System Uptime        → Stat
```

## Main Queries

CPU utilisation:

```
100 * (1 - avg by (instance) (rate(node_cpu_seconds_total{job="node-exporter", mode="idle"}[5m])))
```

Memory utilisation:

```
100 * (1 - (node_memory_MemAvailable_bytes{job="node-exporter"} / node_memory_MemTotal_bytes{job="node-exporter"}))
```

Root disk usage:

```
100 * (1 - (node_filesystem_avail_bytes{job="node-exporter", mountpoint="/"} / node_filesystem_size_bytes{job="node-exporter", mountpoint="/"}))
```

Prometheus target status:

```
up
```

Network received:

```
sum by (instance) (rate(node_network_receive_bytes_total{job="node-exporter", device!~"lo|docker.*|veth.*|br-.*"}[5m]))
```

Network transmitted:

```
sum by (instance) (rate(node_network_transmit_bytes_total{job="node-exporter", device!~"lo|docker.*|veth.*|br-.*"}[5m]))
```

Available memory:

```
node_memory_MemAvailable_bytes{job="node-exporter"}
```

System uptime:

```
time() - node_boot_time_seconds{job="node-exporter"}
```

## Current State

The Grafana dashboard is now stored in the repo as:

monitoring/grafana/dashboards/infra-overview.json

The dashboard uses the stable UID:

infra-monitor-ec2-overview

The Prometheus data source also uses a stable UID:

prometheus

Grafana loads the dashboard through:

monitoring/grafana/provisioning/dashboards/dashboards.yml

The dashboard folder is mounted read-only into the Grafana container.

Grafana then scans the folder and loads the dashboard automatically.

UI changes are disabled for the provisioned dashboard, so the JSON file in Git stays as the source of truth.

Reproducibility Test

I deleted the original Grafana container and the grafana-data volume on purpose.

Then I created a fresh Grafana instance.

Without manually setting anything up again, Grafana automatically loaded:

Prometheus data source
Infra Monitor — EC2 Overview dashboard
all eight dashboard panels

So yeah, the important Grafana setup is now reproducible from Git.

This is a big improvement because the dashboard no longer depends only on an existing Docker volume.

For now, the main thing is that the dashboard works and shows real Linux metrics from Node Exporter. AND that it LOOKS SICK
