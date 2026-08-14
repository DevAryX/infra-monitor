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

---

## Day 3 — Run Node Exporter Locally

Today I added Node Exporter to the Docker Compose setup and ran it locally on my Ubuntu VM.

Node Exporter exposes Linux system metrics through:

```text
http://localhost:9100/metrics
```

These metrics are what Prometheus will scrape later.

### Container Setup

Node Exporter uses:

```text
host network
host PID namespace
read-only host filesystem mount
--path.rootfs=/host
restart unless-stopped
```

This lets it observe the actual Ubuntu VM instead of only seeing inside its own container.

### Architecture Update

The original idea was:

```text
Prometheus → node-exporter:9100
```

But because Node Exporter uses host networking, the better flow is:

```text
Ubuntu VM / EC2 host
    ↓
Node Exporter
    ↓
Host port 9100
    ↓
Prometheus
```

Prometheus and Grafana can still use the internal Docker network later.

### Metrics Checked

I inspected metrics like:

```text
node_cpu_seconds_total
node_memory_MemAvailable_bytes
node_filesystem_avail_bytes
node_network_receive_bytes_total
node_boot_time_seconds
node_exporter_build_info
```

I also compared Node Exporter memory values with `/proc/meminfo`, and they matched.

So Node Exporter is reporting host-level metrics properly.

### What I Learned

Node Exporter does not give nice polished dashboard percentages by itself.

It exposes raw Linux metrics.

Prometheus collects them, PromQL turns them into useful queries, and Grafana makes them visual.

Basically, Node Exporter is the sensor, Prometheus is the collector, Grafana is the screen.


--- 

## Day 4 — Add Prometheus

Today I added Prometheus to the local Docker Compose monitoring stack.

Prometheus collects metrics by scraping HTTP endpoints.

Node Exporter exposes Linux metrics at:

```text
http://localhost:9100/metrics
```

Prometheus now scrapes those metrics every 15 seconds and stores them as time-series data.

### Prometheus Config

The config file is stored at:

```text
monitoring/prometheus/prometheus.yml
```

Current scrape jobs:

```text
prometheus
node-exporter
```

The `prometheus` job lets Prometheus monitor itself.

The `node-exporter` job collects Linux host metrics.

### Node Exporter Target

Node Exporter uses host networking, so Prometheus reaches it through:

```text
host.docker.internal:9100
```

This works through Docker’s host gateway mapping.

Prometheus itself joins the internal Docker network:

```text
monitoring-net
```

Grafana will later join the same network and connect to Prometheus using:

```text
prometheus:9090
```

### Storage

Prometheus stores metrics in:

```text
/prometheus
```

This is backed by the Docker volume:

```text
prometheus-data
```

Retention is set to 7 days, 
That is enough for learning and graphs without wasting disk space.

### Local Access

Prometheus is available locally at:

```text
http://localhost:9090
```

The port is bound to:

```text
127.0.0.1:9090
```

So it is only exposed locally on the Ubuntu VM, not randomly opened everywhere.

### Validation

I checked:

```text
Docker Compose config
Prometheus config with promtool
Prometheus health endpoint
Prometheus readiness endpoint
Docker host gateway mapping
Prometheus scrape targets
```

Both targets were healthy:

```text
prometheus      UP
node-exporter   UP
```

### First PromQL Queries

I tested:

```text
up
up{job="node-exporter"}
```

A value of `1` confirmed Prometheus was successfully scraping Node Exporter.

I also checked metrics like:

```text
node_memory_MemAvailable_bytes
node_memory_MemTotal_bytes
node_boot_time_seconds
node_cpu_seconds_total
```

### So What I Learned

Node Exporter exposes the Linux metrics.

Prometheus collects them again and again with timestamps.

That basically creates the history Grafana will later use for dashboards.

Basically, Node Exporter gives the data, Prometheus stores the data, and Grafana will make it look clean.

---

## Day 5 — PromQL Basics

So today I learned the basics of PromQL.

PromQL is used to turn raw Prometheus metrics into useful monitoring queries.

### Basic Queries

A metric can be queried directly:

```text
node_memory_MemAvailable_bytes
```

Labels can filter the result:

```text
up{job="node-exporter"}
```

This helps focus on one job, instance, CPU mode, filesystem, or network interface.

### Range Queries

A normal query shows the latest value.

A range query looks back over time:

```text
node_cpu_seconds_total[5m]
```

This means the last 5 minutes of data.

### `rate()`

Some metrics are counters, not percentages.

Example:

```text
node_cpu_seconds_total
```

This keeps increasing over time.

To make it useful, I used:

```text
rate(node_cpu_seconds_total[5m])
```

This shows how fast the counter changed over the last 5 minutes.

### Aggregation

Node Exporter exposes lots of separate metrics, like one per CPU core or network interface.

PromQL can combine them using:

```text
avg
sum
```

This makes the data easier to use in dashboards.

### Queries Created

I created PromQL queries for:

```text
Node Exporter health
CPU usage
Memory usage
Root disk usage
Network receive rate
Network transmit rate
```

The reusable queries are documented in:

```text
monitoring/prometheus/promql-basics.md
```

### Verification

I compared some Prometheus values with Linux commands:

```bash
free -h
df -h /
ip -brief link
```

I also created temporary CPU load and watched the CPU query react.

### What I Learned

Raw metrics are not always dashboard-ready.
Node Exporter exposes the data, then Prometheus stores it.
Then PromQL turns it into useful information.

These queries will be the base for the Grafana dashboard.

---

## Day 6 — Add Grafana

Today I added Grafana as the visual part of the monitoring stack.

The monitoring flow is now:

```text
Ubuntu Linux host
    ↓
Node Exporter
    ↓
Prometheus
    ↓
Grafana
```

madd stufff

Node Exporter exposes the Linux metrics.

Prometheus scrapes and stores them.

Grafana queries Prometheus and turns the metrics into dashboards.

### Docker Setup

Grafana runs through the existing Docker Compose setup using:

```text
grafana/grafana:13.1.3
```

It joins the same Docker network as Prometheus:

```text
monitoring-net
```

Grafana connects to Prometheus using:

```text
http://prometheus:9090
```

This is important because `localhost` inside the Grafana container would mean Grafana itself, not Prometheus.

### Persistence

Grafana stores its data in:

```text
/var/lib/grafana
```

using the Docker volume:

```text
grafana-data
```

This means settings and dashboards should survive normal container restarts.

### Local Access

Grafana is bound to:

```text
127.0.0.1:3000
```

and can be accessed on the Ubuntu VM at:

```text
http://localhost:3000
```

The default admin password was changed during setup and was NOT saved in the repo

### Verification

I connected Grafana to the Prometheus data source.

Then I tested PromQL queries in Grafana Explore, including:

```text
up{job="node-exporter"}
```

and:

```text
node_memory_MemAvailable_bytes{job="node-exporter"}
```

This confirmed Grafana can read the metrics Prometheus collected. it was amazing

---

## Day 7 — Build the Main Grafana Dashboard

Today I built the main Grafana dashboard.

The dashboard is named:

```text
Infra Monitor — EC2 Overview
```

Right now it is showing metrics from my local Ubuntu VM before I move the monitoring stack onto EC2.

### Panels Added

The dashboard currently has eight panels:

```text
CPU utilisation
Memory utilisation
Root disk usage
Prometheus target status
Network received
Network transmitted
Available memory
System uptime
```

### Visualisations

I used gauges for CPU, memory, and disk because they are percentage-based.

I used stat panels for target status, available memory, and uptime.

I used time-series panels for network traffic because it makes more sense to see how traffic changes over time.

### Target Status

The dashboard uses the Prometheus `up` metric to show target health.

Grafana maps the values like this:

```text
1 → UP
0 → DOWN
```

This is much cleaner than staring at random `1` and `0` values.

### Network Panels

The network queries filter out loopback and Docker virtual interfaces.

This keeps the dashboard focused on real host traffic instead of container noise.

The queries also avoid depending on one exact interface name, which should make it easier to move from the Ubuntu VM to EC2 later.

### Verification

I compared dashboard values with Linux commands:

```bash
free -h
df -h /
uptime -p
top
```

This helped confirm the dashboard was showing real host data properly.

### Current State

The dashboard is currently saved inside the `grafana-data` Docker volume.

It has not been exported as JSON yet.


### Current Flow

```text
Ubuntu VM
    ↓
Node Exporter
    ↓
Prometheus
    ↓
PromQL
    ↓
Grafana
    ↓
Infra Monitor — EC2 Overview
```

### What I Learned

A Grafana dashboard is basically queries plus visualisations.

PromQL does the calculations and setting it up is actually quite simple.

---

## Day 8 — Persistence and Restart Testing

Today I tested if the monitoring stack could survive Docker container recreation without losing important data.

### Persistent Volumes

Prometheus uses:

```
prometheus-data → /prometheus
```

Grafana uses:

```
grafana-data → /var/lib/grafana
```

These volumes store the important data outside the containers.

### Recreation Test

Before stopping the stack, I recorded the Prometheus and Grafana container IDs.

Then I ran:

```
docker compose -f docker/docker-compose.yml down
```

This removed the containers, but not the named volumes.

I then recreated the stack:

```
docker compose -f docker/docker-compose.yml up -d
```

The new Prometheus and Grafana containers had different container IDs, so they were properly recreated.

### Results

Prometheus kept old metric data from before the container was removed.

Grafana also kept:

```
admin settings
Prometheus data source
Infra Monitor — EC2 Overview dashboard
all dashboard panels
```

So yeah, the named volumes worked properly.

### Persistence vs Reproducibility

Docker volumes give persistence on the current machine.

But they do not make everything fully reproducible from Git yet.

```
Persistent
→ survives container replacement

Reproducible
→ can be rebuilt from Git-tracked config
```

### What I Learned

Important data should live outside the container filesystem.

This test proved that Prometheus and Grafana can survive normal container recreation, but the next step is still Grafana provisioning so the setup can be rebuilt properly from Git.
