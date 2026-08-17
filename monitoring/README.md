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

### Grafana Provisioning

Grafana is now partly managed as code.

The Prometheus data source is defined in:

```text id="8mlbhy"
monitoring/grafana/provisioning/datasources/prometheus.yml
```

The dashboard provider is defined in:

```text id="oh3pl7"
monitoring/grafana/provisioning/dashboards/dashboards.yml
```

The main dashboard is stored as:

```text id="pavvna"
monitoring/grafana/dashboards/infra-overview.json
```

Stable UIDs are used:

```text id="bkht7n"
Prometheus data source → prometheus
Main dashboard          → infra-monitor-ec2-overview
```

The provisioning files and dashboard folder are mounted read-only into the Grafana container.

This means Grafana no longer depends on me manually creating the data source and dashboard in the UI.

I also tested a fresh `grafana-data` volume, and Grafana automatically brought back the Prometheus data source and the full dashboard from the Git-tracked files.

So yeah, the dashboard setup is now actually reproducible instead of only surviving through a Docker volume.


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

### Persistence Testing

The monitoring stack uses named Docker volumes for data that needs to survive container recreation.

Prometheus uses:

```
prometheus-data → /prometheus
```

Grafana uses:

```
grafana-data → /var/lib/grafana
```

I tested this by stopping and recreating the Compose containers.

After recreation:

```
Prometheus kept old metrics
Grafana kept the dashboard
Grafana kept the Prometheus data source
Grafana kept its settings
new containers reattached the same volumes
```

The full test is documented in:

```
monitoring/persistence-test.md
```

So, Docker volumes protect the monitoring state from normal container recreation.

But this is still not full reproducibility from Git yet.

Grafana provisioning will be added next so the dashboard and data source can be rebuilt from version-controlled files.

---

### EC2 Deployment

The complete monitoring stack has now been deployed to the Terraform-managed Amazon Linux EC2 server.

The cloud monitoring flow is:

```text
Amazon Linux EC2
    ↓
Node Exporter
    ↓
Prometheus
    ↓
Grafana
```

The stack is deployed using the existing GitHub Actions CI/CD pipeline.

Prometheus and Grafana remain bound to EC2 localhost and can be accessed through SSH port forwarding.

Deployment and results are documented in:

```
monitoring/ec2-deployment-test.md
```

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

### Current Grafana Implementation

Grafana now runs locally through Docker Compose using:

```text
grafana/grafana:13.1.3
```

Grafana listens on port:

```text
3000
```

The local binding is:

```text
127.0.0.1:3000
```

So I can access it from the Ubuntu VM at:

```text
http://localhost:3000
```

without exposing it on every network interface.

Grafana and Prometheus both use the Docker network:

```text
monitoring-net
```

Grafana connects to Prometheus with:

```text
http://prometheus:9090
```

This works because Docker Compose service names can be used between containers.

Important note: `localhost` inside the Grafana container would mean Grafana itself, not Prometheus.

Grafana stores its data in:

```text
/var/lib/grafana
```

using the named volume:

```text
grafana-data
```

The Prometheus data source was configured manually for now.

Later, Grafana provisioning will move the data source and dashboard setup into files stored in Git.

---

### Main Dashboard

The main Grafana dashboard is:

```text
Infra Monitor — EC2 Overview
```

It currently shows:

```text
CPU utilisation
Memory utilisation
Root filesystem usage
Prometheus target status
Network receive traffic
Network transmit traffic
Available memory
System uptime
```

The dashboard uses the PromQL queries created earlier in the monitoring phase.

Dashboard notes are stored at:

```text
monitoring/grafana/dashboard-notes.md
```

Right now, the dashboard is saved through the `grafana-data` Docker volume.

Later, I will export it as JSON and provision it from Git, so the dashboard can be recreated automatically instead of only living inside Grafana.

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
