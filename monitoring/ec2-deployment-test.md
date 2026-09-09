# EC2 Monitoring Stack Deployment Test

## Purpose

This test verified that the monitoring stack developed locally could run correctly on the Terraform-managed Amazon Linux EC2 instance.

## Deployment Path

```text
GitHub main
    ↓
GitHub Actions validation
    ↓
Exact tested commit SHA
    ↓
Temporary runner /32 SSH access
    ↓
EC2 checkout reset to tested SHA
    ↓
scripts/deploy-infra-monitor.sh
    ↓
Docker Compose
    ↓
Post-deployment health check
```

GitHub Actions deploys the exact commit that passed the current CI workflow rather than blindly deploying the newest state of `main`.

The EC2 checkout is reset to that tested commit before `scripts/deploy-infra-monitor.sh` validates and deploys the stack.

## EC2 Services

The stack on EC2 includes:

```text
infra-monitor
node-exporter
prometheus
grafana
```

Node Exporter, Prometheus, and Grafana run as long-running services.

The `infra-monitor` container is a one-shot workload. It runs `system_report.sh`, writes the report and custom Prometheus metrics, then exits successfully with code `0`.

## Prometheus Check

Prometheus showed both scrape targets as healthy:

```text
prometheus    → UP
node-exporter → UP
```

I also queried `node_uname_info` and compared the result with the EC2 hostname.

This confirmed that Node Exporter was reporting metrics from the EC2 host rather than the local Ubuntu development VM.

## Grafana Check

Grafana loaded the provisioned Prometheus data source and dashboard:

```text
Infra Monitor — EC2 Overview
```

The dashboard contains eleven panels:

```text
CPU Utilisation
Memory Utilisation
Root Disk Usage
Prometheus Target Status
Network Received
Network Transmitted
Available Memory
System Uptime
Time Since Last Successful Report
Infra Monitor Warning State
Infra Monitor Report Status
```

Grafana is accessed through an SSH tunnel rather than by exposing port `3000` publicly.

## Resource Check

EC2 resource usage was checked with:

```bash
free -h
df -h /
docker stats --no-stream
```

Deployment evidence is available here:

[View EC2 Grafana dashboard proof](../proof/aug_imgs/day10-ec2-grafana-dashboard.png)

## Result

The complete monitoring stack successfully deployed to the Terraform-managed EC2 host.

The test confirmed that the project could move from local monitoring development to a reproducible cloud deployment with Prometheus, Grafana, Node Exporter and the custom Infra Monitor workload operating together.
