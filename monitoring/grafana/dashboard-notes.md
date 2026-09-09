# Grafana Dashboard

## Dashboard

The main dashboard is named:

```text
Infra Monitor — EC2 Overview
```

The dashboard was initially developed and tested locally on the Ubuntu VM before being deployed to the Terraform-managed EC2 monitoring stack.

Grafana uses Prometheus as its data source.

Prometheus receives Linux host metrics from Node Exporter and custom Infra Monitor metrics through the Node Exporter textfile collector.

The monitoring flow is:

```text
Infra Monitor
    ↓ custom .prom metrics
Node Exporter
    ↓
Prometheus
    ↓
Grafana dashboard
```

## Panels

The provisioned dashboard contains eleven panels:

```text
CPU Utilisation                   → Gauge
Memory Utilisation                → Gauge
Root Disk Usage                   → Gauge
Prometheus Target Status          → Stat
Network Received                  → Time series
Network Transmitted               → Time series
Available Memory                  → Stat
System Uptime                     → Stat
Time Since Last Successful Report → Stat
Infra Monitor Warning State       → Stat
Infra Monitor Report Status       → Stat
```

## Main Queries

### CPU Utilisation

```promql
100 * (
  1 -
  avg by (instance) (
    rate(
      node_cpu_seconds_total{
        job="node-exporter",
        mode="idle"
      }[5m]
    )
  )
)
```

### Memory Utilisation

```promql
100 * (
  1 -
  (
    node_memory_MemAvailable_bytes{
      job="node-exporter"
    }
    /
    node_memory_MemTotal_bytes{
      job="node-exporter"
    }
  )
)
```

### Root Disk Usage

```promql
100 * (
  1 -
  (
    node_filesystem_avail_bytes{
      job="node-exporter",
      mountpoint="/"
    }
    /
    node_filesystem_size_bytes{
      job="node-exporter",
      mountpoint="/"
    }
  )
)
```

### Prometheus Target Status

```promql
up
```

### Network Received

```promql
sum by (instance) (
  rate(
    node_network_receive_bytes_total{
      job="node-exporter",
      device!~"lo|docker.*|veth.*|br-.*"
    }[5m]
  )
)
```

### Network Transmitted

```promql
sum by (instance) (
  rate(
    node_network_transmit_bytes_total{
      job="node-exporter",
      device!~"lo|docker.*|veth.*|br-.*"
    }[5m]
  )
)
```

### Available Memory

```promql
node_memory_MemAvailable_bytes{job="node-exporter"}
```

### System Uptime

```promql
time() - node_boot_time_seconds{job="node-exporter"}
```

## Current State

The Grafana dashboard is stored in the repository as:

```text
monitoring/grafana/dashboards/infra-overview.json
```

The dashboard uses the stable UID:

```text
infra-monitor-ec2-overview
```

The Prometheus data source uses the stable UID:

```text
prometheus
```

Grafana loads the dashboard through:

```text
monitoring/grafana/provisioning/dashboards/dashboards.yml
```

The dashboard directory is mounted read-only into the Grafana container.

Grafana scans the provisioned directory and loads the dashboard automatically.

UI changes are disabled for the provisioned dashboard so the JSON stored in Git remains the source of truth.

## Reproducibility Test

The original Grafana container and `grafana-data` volume were deliberately removed during testing.

A fresh Grafana instance was then created.

Without manually rebuilding the configuration, Grafana automatically loaded:

```text
Prometheus data source
Infra Monitor — EC2 Overview dashboard
all eleven dashboard panels
```

This demonstrated that the important Grafana configuration is reproducible from version-controlled provisioning rather than depending only on an existing Docker volume.

The result is a reproducible dashboard that presents both Linux host health and custom Infra Monitor application state from version-controlled configuration.
