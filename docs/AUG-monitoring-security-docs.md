# August 2026 — Monitoring and Security

## Phase Goal

The goal of August is to add security improvements to the existing infra-monitor project.

The project will be expanded with:

- Node Exporter for Linux host metrics
- Prometheus for collecting and storing metrics
- Grafana for dashboards and visualisation
- Secure access to monitoring services
- Improved secrets management
- IAM least-privilege permissions
- Custom metrics from the original Bash monitoring script

---

## Day 1 — Observability Mental Model

### What is monitoring?

Monitoring means like collecting and checking information about the system, such as:

- Is the CPU usage too high?

- Is the server running?

### What is observability?

Observability is the ability to understand what is happening inside a system by examining the info it shows.
A system with good observability helps you investiagte questions you did not predict beforehand.

Monitoring is like: Is memory usage above 90%?

Observaility is like: When did the memory begin increasing?
What else happened at the same time? / Was CPU, disk or network also affected?

### Monitoring vs logging

Logs are records of individual events.

Examples: 

```
2026-07-21 01:10:00 INFO System report started
2026-07-21 01:10:01 WARNING Disk usage exceeded threshold
2026-07-21 01:10:02 INFO System report completed
```

### Metrics vs logs

Metrics are NUMERICAL measurements.

Examples: 

```
CPU utilisation: 37%
Available memory: 412 MB
Disk space available: 18 GB
```

Unlike logs, with metrics you can track behaviours overtime and make graphs to see how it has progessed.
Prometheus stores metric values together with timestamps and optional labels.

The metric shows the measurable state.

The log explains the event and gives you the readable context.

### What is time-series data?

Time series data is a sequence of measurements recorded at different times.

For example:
```
10:00 → CPU 20%
10:01 → CPU 31%
10:02 → CPU 78%
```
The time series shows the pattern, spike or recovery.

### What is scraping?

Scraping is when Prometheus sends an HTTP request to a target and collects the metrics that target exposes.

For example:
```
Prometheus
    ↓ HTTP request
node-exporter:9100/metrics
    ↓ response
Linux system metrics
```

### What is an exporter?

An exporter exposes info from another system in a format Prometheus understands.
Node Exporter reads Linux host info and exposes hardware and jernel related metrics.

### What is a dashboard?

A dashboard groups useful info all together.

Inshallah my one will eventually display: 
```
CPU utilisation
Memory usage
Disk usage
Network traffic
System uptime
Prometheus target health
Bash script success
```

### What is an alert?

An alert is a condition that becomes active when a difined rule is met.

Examples: 
```
Disk usage above 90%
Node Exporter unavailable
Monitoring script has not completed recently
EC2 memory dangerously low
```

---

## Day 2 — Monitoring Architecture and Repository Scaffold

Okay so today I planned the monitoring architecture before adding more containers.

I created a dedicated folder for monitoring config:

```text
monitoring/
├── prometheus/
└── grafana/
```

The main Docker Compose file will still stay here:

```text
docker/docker-compose.yml
```

This keeps the config organised without splitting the project into random separate parts.

### Planned Architecture

```text
Terraform
    ↓
AWS EC2
    ↓
Docker Compose
    ├── infra-monitor
    ├── node-exporter
    ├── prometheus
    └── grafana
```

### Data Flow

```text
Linux host
    ↓
Node Exporter exposes metrics
    ↓
Prometheus scrapes and stores metrics
    ↓
Grafana displays dashboards
```

### Main Decisions

The monitoring services will eventually use an internal Docker network:

```text
monitoring-net
```

Services will talk using Compose names:

```text
Prometheus → node-exporter:9100
Grafana → prometheus:9090
```

Prometheus and Grafana will use named volumes:

```text
prometheus-data
grafana-data
```

Prometheus will initially keep around 7 days of metrics. That is enough for learning, graphs, and testing without wasting disk space.

### Security

Grafana will later be accessed through an SSH tunnel from my Ubuntu VM.

Also for rn, no Kubernetes, external databases, distributed storage, or extra tools yet.





