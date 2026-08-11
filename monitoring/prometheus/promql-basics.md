# PromQL Basics

## Purpose

So this is the file which records the PromQL queries used by the Infra Monitor project.

PromQL is used to turn the raw metrics collected by Prometheus into useful information about host health and resource usage. (whole lotta stuff)

## Core Concepts

### Metric Selector

A metric name selects matching time series.

Example:

```promql
node_memory_MemAvailable_bytes
```

### Label Selector

Labels can narrow a query to specific time series.

Example:

```promql
up{job="node-exporter"}
```

### Range Vector

A range selector retrieves samples covering a period of time.

Example:

```promql
node_cpu_seconds_total[5m]
```

The `[5m]` selector represents the previous five minutes of samples.

### rate()

Counters normally increase over time.

`rate()` calculates the average per-second rate of increase over a selected time range.

Example:

```promql
rate(node_cpu_seconds_total[5m])
```

### Aggregation

PromQL can combine multiple time series using operators such as `avg` and `sum`.

This is useful when metrics contain one series per CPU core or network interface.

---

## Useful Infra Monitor Queries

### Node Exporter Health

```promql
up{job="node-exporter"}
```

Expected healthy value:

```text
1
```

### CPU Utilisation Percentage

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

This calculates average non-idle CPU utilisation across the host CPUs.

### Memory Utilisation Percentage

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

This calculates the percentage of system memory that is not currently available.

### Root Filesystem Utilisation Percentage

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

The root filesystem mount label was checked before using this query.

### Network Receive Rate

```promql
sum by (instance) (
  rate(
    node_network_receive_bytes_total{
      job="node-exporter",
      device!="lo"
    }[5m]
  )
)
```

This returns the average number of non-loopback network bytes received per second.

### Network Transmit Rate

```promql
sum by (instance) (
  rate(
    node_network_transmit_bytes_total{
      job="node-exporter",
      device!="lo"
    }[5m]
  )
)
```

This returns the average number of non-loopback network bytes transmitted per second.

## Dashboard Direction

These queries will later form the basis of the Grafana dashboard.

The planned dashboard will convert the stored Prometheus metrics into panels for:

* Target health
* CPU utilisation
* Memory utilisation
* Disk utilisation
* Network receive traffic
* Network transmit traffic

