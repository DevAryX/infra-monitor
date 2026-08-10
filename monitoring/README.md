# Monitoring Stack

## Purpose

This folder contains the monitoring setup for `infra-monitor`.

The goal is to add proper observability to the project.

The stack will collect Linux host metrics, store them over time, and display them in Grafana dashboards.

This will be added to the existing Docker Compose setup, not treated like a separate project.

---

## Planned Components

### Infra Monitor

The original Bash monitoring app.

It currently:

* Generates system reports
* Writes logs
* Uploads to S3 when configured
* Handles basic errors

Later, it will also expose custom metrics.

### Node Exporter

Node Exporter collects Linux host metrics.

Examples:

* CPU usage
* Memory usage
* Disk usage
* Network traffic
* System uptime

Basically, it lets Prometheus see what the server is doing.

### Current Node Exporter Implementation

Node Exporter is now running locally through Docker Compose.

It uses:

```yaml
network_mode: host
pid: host
```

The Ubuntu host filesystem is mounted read-only at:

```text
/host
```

Node Exporter is configured with:

```text
--path.rootfs=/host
```

This lets the containerised exporter read host-level Linux metrics instead of only watching its own container environment.

The local metrics endpoint is:

```text
http://localhost:9100/metrics
```

Prometheus will be connected to this endpoint during Day 4.

### Prometheus

Prometheus will scrape metrics from Node Exporter and store them as time-series data.

It will handle:

* Metric collection
* Local metric storage
* PromQL queries
* Target health checks
* Data source for Grafana

### Grafana

Grafana will show the metrics in dashboards.

Planned dashboard name:

```text
Infra Monitor - EC2 Overview
```

This is where the project becomes more visual instead of just logs in a terminal.

---

## Monitoring Flow

```text
Linux host
    ↓
Node Exporter
    ↓
Prometheus
    ↓
Grafana
    ↓
Infra Monitor dashboard
```

Simple idea:

```text
Node Exporter exposes metrics
Prometheus collects and stores them
Grafana displays them
```

---

## Repository Layout

Planned structure:

```text
monitoring/
├── prometheus/
│   └── prometheus.yml
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml
│   │   └── dashboards/
│   │       └── dashboards.yml
│   └── dashboards/
│       └── infra-overview.json
└── README.md
```

Some files will be added later as each monitoring part is slowly being built.

---

## Docker Compose Plan

The monitoring services will be added to:

```text
docker/docker-compose.yml
```

Planned services:

```text
infra-monitor
node-exporter
prometheus
grafana
```

The goal is to keep one Compose file as the main source of truth for the full stack.

---

## Networking Plan

The monitoring containers will use an internal Docker network:

```text
monitoring-net
```

Services will talk using Docker Compose names instead of hard-coded IP addresses.

Current planned connections:

```text
Prometheus → host.docker.internal:9100
Grafana → prometheus:9090
```

Node Exporter is the exception because it uses host networking to collect proper host metrics.

Prometheus will later use Docker’s host-gateway mapping to reach Node Exporter from the internal monitoring network.

No random container IP nonsense, the service names are cleaner.

---

## Persistence Plan

Docker named volumes will be used for data that should survive container restarts.

Planned volumes:

```text
prometheus-data
grafana-data
```

Prometheus data should survive so recent metrics are not lost straight away.

Grafana data should survive so dashboards and settings do not disappear every time the container restarts.

Prometheus retention will probably start at around 7 days.

This is enough for learning, testing graphs, and keeping disk usage low.

---

## Security Plan

Monitoring tools should not be exposed to the public internet for no reason.

Planned access:

```text
Node Exporter → host/local access only
Prometheus    → internal only / local troubleshooting
Grafana       → accessed through SSH tunnel
```

Planned ports:

```text
Node Exporter → 9100
Prometheus    → 9090
Grafana       → 3000
```

The idea is to keep the monitoring stack useful but not wide open.

---

## Out of Scope, for now

This phase will not add:

```text
Kubernetes
Loki
distributed tracing
external databases
public reverse proxy
random extra monitoring tools
```

The goal is simple: understand Node Exporter, Prometheus, and Grafana properly first.

No need to overdo it.

---

### Current Prometheus Implementation

Prometheus now runs locally through Docker Compose using:

```text
prom/prometheus:v3.13.2
```

The config file is stored at:

```text
monitoring/prometheus/prometheus.yml
```

Prometheus currently scrapes:

```text
localhost:9090
host.docker.internal:9100
```

The first target lets Prometheus monitor itself.

The second target connects to Node Exporter, which is running with host networking.

Prometheus uses Docker’s host gateway mapping:

```yaml
extra_hosts:
  - "host.docker.internal=host-gateway"
```

This lets the Prometheus container reach Node Exporter through the Docker host.

Prometheus stores its data in:

```text
/prometheus
```

using the named Docker volume:

```text
prometheus-data
```

Prometheus retention is configured for seven days using:

```text
--storage.tsdb.retention.time=7d
```

Local Prometheus access is available at:

```text
http://localhost:9090
```

The port is bound to the Ubuntu VM loopback interface, so it is not exposed on all network interfaces.

---

## Environment Flow

```text
Windows 11 host
    ↓
Ubuntu 22.04 VM
    ↓
Terraform, Git, SSH
    ↓
Amazon Linux 2023 EC2
    ↓
Docker Compose monitoring stack
```

The EC2 private key stays outside the repo.

It should never be copied into:

```text
GitHub
Docker images
Terraform files
GitHub Actions logs
monitoring config
```

## Result

This monitoring stack will move `infra-monitor` from basic logs to proper metrics and dashboards.

Inshallah by the end of this phase, the project should show what the EC2 server is doing instead of only writing reports in the background.
