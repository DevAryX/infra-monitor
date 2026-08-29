# Monitoring Stack

## Purpose

This folder contains the monitoring setup for `infra-monitor`.

The goal is to give the project proper observability, not just logs.

The stack collects Linux host metrics, custom Bash app metrics, stores them in Prometheus, and displays them in Grafana.

This is part of the existing Docker Compose deployment, not a separate random side project.

---

## Final Architecture

```text
                         GitHub
                            │
                            ↓
                      GitHub Actions
                            │
             ┌──────────────┼──────────────┐
             ↓              ↓              ↓
          Validate         Build      Integration
             └──────────────┼──────────────┘
                            ↓
                         Deploy
                            ↓
                      Health Check
                            ↓
                         AWS EC2
                            │
             ┌──────────────┼──────────────┐
             │              │              │
             ↓              ↓              ↓
      infra-monitor    Node Exporter   Prometheus
             │              │              │
             │       host metrics          │
             │              │              │
             └── .prom ─────┘              │
                            │              │
                            └───────→───────┘
                                           │
                                           ↓
                                        Grafana
                                           │
                                     SSH tunnel only
                                           │
                                           ↓
                                      Ubuntu browser


EC2
 ↓
IAM Instance Profile
 ↓
Least-Privilege IAM Role
 ↓
S3 report upload
```

A monitored cloud setup with CI/CD, metrics, dashboards, secure access, and IAM.

---

## Components

### Infra Monitor

The original Bash monitoring app.

It:

* Generates system reports
* Writes logs
* Uploads reports to S3 when configured
* Publishes custom Prometheus metrics
* Runs as a one-shot container workload

The app is not meant to run forever. It runs the report, writes the output, then exits successfully.

### Node Exporter

Node Exporter collects Linux host metrics from the EC2 server.

Examples:

* CPU usage
* Memory usage
* Disk usage
* Network traffic
* System uptime

It also exposes custom `infra_monitor_*` metrics through the textfile collector.

### Prometheus

Prometheus scrapes metrics from Node Exporter and stores them as time-series data.

It handles:

* Metric scraping
* PromQL queries
* Target health
* Local metric storage
* Data source for Grafana

### Grafana

Grafana visualises the Prometheus metrics.

It provides the main dashboard:

```text
Infra Monitor — EC2 Overview
```

This dashboard shows EC2 system health and custom Infra Monitor app health.

---

## Docker Compose Stack

The monitoring stack runs through:

```text
docker/docker-compose.yml
```

Current services:

```text
infra-monitor
node-exporter
prometheus
grafana
```

The goal is to keep one Compose file as the main source of truth for the full stack.

---

## Networking

The monitoring services use the internal Docker network:

```text
monitoring-net
```

Grafana connects to Prometheus using the Compose service name:

```text
http://prometheus:9090
```

Node Exporter uses host networking so it can read proper host-level Linux metrics.

Prometheus reaches Node Exporter through:

```text
host.docker.internal:9100
```

using Docker’s host gateway mapping.

No hard-coded container IPs. Service names and host gateway are cleaner.

---

## Node Exporter

Node Exporter runs with:

```yaml
network_mode: host
pid: host
```

The host filesystem is mounted read-only at:

```text
/host
```

and Node Exporter uses:

```text
--path.rootfs=/host
```

This lets it report host metrics instead of only seeing inside its own container.

Metrics endpoint:

```text
http://localhost:9100/metrics
```

---

## Prometheus

Prometheus runs through Docker Compose using:

```text
prom/prometheus:v3.13.2
```

Config file:

```text
monitoring/prometheus/prometheus.yml
```

Current scrape targets:

```text
localhost:9090
host.docker.internal:9100
```

Prometheus stores data in:

```text
/prometheus
```

using the named volume:

```text
prometheus-data
```

Retention is configured for seven days:

```text
--storage.tsdb.retention.time=7d
```

Local access:

```text
http://localhost:9090
```

The port is bound to localhost, not every network interface.

---

## Grafana

Grafana runs through Docker Compose using:

```text
grafana/grafana:13.1.3
```

Local binding:

```text
127.0.0.1:3000
```

Local access:

```text
http://localhost:3000
```

Grafana stores runtime data in:

```text
/var/lib/grafana
```

using the named volume:

```text
grafana-data
```

---

## Grafana Provisioning

Grafana is now partly managed as code.

The Prometheus data source is defined in:

```text
monitoring/grafana/provisioning/datasources/prometheus.yml
```

The dashboard provider is defined in:

```text
monitoring/grafana/provisioning/dashboards/dashboards.yml
```

The main dashboard is stored as:

```text
monitoring/grafana/dashboards/infra-overview.json
```

Stable UIDs are used:

```text
Prometheus data source → prometheus
Main dashboard          → infra-monitor-ec2-overview
```

The provisioning files and dashboard folder are mounted read-only into the Grafana container.

This means Grafana does not depend on me manually clicking around in the UI to recreate the main dashboard.

I tested a fresh `grafana-data` volume, and Grafana automatically brought back the Prometheus data source and dashboard from the Git-tracked files.

So the dashboard setup is now reproducible.

---

## Main Dashboard

The main dashboard is:

```text
Infra Monitor — EC2 Overview
```

It shows:

```text
CPU utilisation
Memory utilisation
Root filesystem usage
Prometheus target status
Network receive traffic
Network transmit traffic
Available memory
System uptime
Time since last successful report
Infra Monitor warning state
Infra Monitor report status
```

Dashboard notes are stored in:

```text
monitoring/grafana/dashboard-notes.md
```

---

## Custom Bash Metrics

The original `system_report.sh` script now publishes custom Prometheus metrics through Node Exporter’s textfile collector.

Metric flow:

```text
system_report.sh
↓
infra_monitor.prom
↓
Node Exporter
↓
Prometheus
↓
Grafana
```

The custom metrics use the `infra_monitor_` prefix.

Examples:

```text
infra_monitor_last_run_timestamp_seconds
infra_monitor_last_success_timestamp_seconds
infra_monitor_cpu_warning
infra_monitor_memory_warning
infra_monitor_disk_warning
infra_monitor_overall_warning
infra_monitor_report_success
```

So the Bash script is not just writing logs anymore.

It now feeds application metrics into the monitoring stack.

Metric definitions are documented in:

```text
monitoring/prometheus/custom-metrics.md
```

---

## Persistence Testing

The monitoring stack uses named Docker volumes for data that needs to survive normal container recreation.

Prometheus uses:

```text
prometheus-data → /prometheus
```

Grafana uses:

```text
grafana-data → /var/lib/grafana
```

I tested stopping and recreating the Compose containers.

After recreation:

```text
Prometheus kept old metrics
Grafana kept its state
Grafana kept the dashboard
Grafana kept the Prometheus data source
new containers reattached the same volumes
```

The full test is documented in:

```text
monitoring/persistence-test.md
```

Persistence protects state from normal container recreation.

Provisioning protects the important Grafana config if the Grafana volume is lost.

Both matter.

---

## EC2 Deployment

The full monitoring stack has been deployed to the Terraform-managed Amazon Linux EC2 server.

Cloud monitoring flow:

```text
Amazon Linux EC2
↓
Node Exporter
↓
Prometheus
↓
Grafana
↓
Infra Monitor — EC2 Overview
```

Deployment uses the existing GitHub Actions CI/CD pipeline.

Deployment and verification are documented in:

```text
monitoring/ec2-deployment-test.md
```

---

## Secure Monitoring Access

The monitoring tools are not exposed through permanent public Security Group rules.

Public EC2 access is limited to SSH:

```text
port 22 → trusted /32 CIDR only
```

Grafana is bound to:

```text
127.0.0.1:3000
```

Prometheus is bound to:

```text
127.0.0.1:9090
```

Node Exporter uses host networking on:

```text
9100
```

but the Terraform Security Group does not allow public access to that port.

Grafana and Prometheus are accessed from my Ubuntu VM using SSH tunnels.

Because my Ubuntu VM also has local monitoring running, EC2 uses different local tunnel ports:

```text
localhost:13000 → EC2 Grafana
localhost:19090 → EC2 Prometheus
```

The full secure access test is documented in:

```text
monitoring/secure-access.md
```

So yeah, the services are reachable when I need them, but not just sitting open on the internet.

---

## Secrets and Runtime Config

Runtime configuration and real credentials are kept separate from safe example files.

Tracked example file:

```text
docker/runtime.env.example
```

Ignored real runtime file:

```text
docker/runtime.env
```

External Grafana credentials:

```text
~/.config/infra-monitor/grafana.env
```

The EC2 private key stays outside the repo as well.

It should never be copied into:

```text
GitHub
Docker images
Terraform files
GitHub Actions logs
monitoring config
```

---

## IAM Least Privilege

The EC2 workload now uses a Terraform-managed IAM role and instance profile.

Permission flow:

```text
EC2
↓
IAM Instance Profile
↓
Least-Privilege IAM Role
↓
S3 report upload
```

The monitoring app does not need long-lived AWS access keys on the server.

The custom IAM policy only allows the S3 upload operation the app actually needs.

Much cleaner than leaving AWS keys sitting around.

---

## CI/CD Monitoring Validation

The GitHub Actions pipeline now checks the monitoring stack before deploying to EC2.

Current flow:

```text
Bash checks
↓
Docker build
↓
Compose + monitoring config validation
↓
Monitoring integration test
↓
EC2 deployment
↓
Post-deploy health check
```

Prometheus config is validated with `promtool`.

The integration test starts Node Exporter, Prometheus, Grafana, and the Infra Monitor workload on the GitHub runner.

It then checks that the custom metrics flow works end-to-end.

After deployment, EC2 runs the same monitoring health check.

If the monitoring services or custom metrics are broken, the deployment fails instead of silently shipping a dead stack.

---

## Failure and Recovery Testing

The final monitoring phase tested:

```text
Node Exporter failure and recovery
Grafana container recreation
Prometheus container recreation
Prometheus persistent history
EC2 reboot
restart policies
secure port exposure
IAM role access
S3 upload
CI/CD health checks
```

The stack recovered while keeping the expected data and security controls.

This is stronger than just taking screenshots when everything is already healthy.

---

## Repository Layout

```text
monitoring/
├── prometheus/
│   ├── prometheus.yml
│   ├── promql-basics.md
│   └── custom-metrics.md
├── grafana/
│   ├── dashboard-notes.md
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml
│   │   └── dashboards/
│   │       └── dashboards.yml
│   └── dashboards/
│       └── infra-overview.json
├── persistence-test.md
├── iam-least-privilege.md
├── ec2-deployment-test.md
└── README.md
```

---

## Out of Scope

This phase does not add:

```text
Kubernetes
Loki
distributed tracing
external databases
public reverse proxy
random extra monitoring tools
```

The point was to understand Node Exporter, Prometheus, Grafana, secure access, and IAM properly first.

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

---

## Result

This monitoring stack moved `infra-monitor` from basic logs to proper metrics, dashboards, custom app health, secure access, CI/CD validation, and least-privilege AWS permissions.

Inshallah, this is now a proper monitored cloud infrastructure project, not just a Bash script running in the background.
