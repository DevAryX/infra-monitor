# EC2 Monitoring Stack Deployment Test

## Purpose

This test was to check if the monitoring stack I built locally could run properly on the Terraform-managed Amazon Linux EC2 instance.

## Deployment Path

```text
GitHub main
    
GitHub Actions
    
SSH deployment
    
EC2
    
deploy-infra-monitor.sh
    
Docker Compose
```

The deploy script pulls the latest `main`, validates Docker Compose, rebuilds the app image, and starts the full stack.

## EC2 Services

The stack on EC2 now includes:

```text
infra-monitor
node-exporter
prometheus
grafana
```

Node Exporter, Prometheus, and Grafana run as long-running services.

The `infra-monitor` container is a one-shot workload. It runs `system_report.sh`, writes the report, then exits successfully with code `0`. 

## Prometheus Check

Prometheus showed both scrape targets as healthy:

```text
prometheus    → UP
node-exporter → UP
```

I also queried `node_uname_info` and compared the result with the EC2 hostname.

This confirmed Node Exporter was reporting EC2 metrics, not my local Ubuntu VM.

## Grafana Check

Grafana loaded the provisioned Prometheus data source and the dashboard:

```text id="p7yydm"
Infra Monitor - EC2 Overview
```

The dashboard shows:

```text id="av33ie"
CPU utilisation
Memory utilisation
Root disk usage
Prometheus target status
Network received
Network transmitted
Available memory
System uptime
```

Grafana was accessed through an SSH tunnel, not by opening port `3000` publicly.

## Resource Check

I checked EC2 resources with:

```bash id="rjlptg"
free -h
df -h /
docker stats --no-stream
```

Actual result:

```text id="8k4z06"
Check proof/aug_imgs/day10_xxx
```

## Result

The monitoring stack successfully deployed to EC2.

So yeah, the project has now moved from local monitoring testing to a proper cloud monitoring setup running on the AWS server. madness
