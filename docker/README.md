# Docker Setup

This folder contains the Docker setup for `infra-monitor`.

Docker is used to package the monitoring script into a container, so it can run properly on my Ubuntu VM, AWS EC2, and future servers without the setup becoming a mess every time.

## Files

```text
docker/
├── Dockerfile
├── docker-compose.yml
└── day9.env
```

## Dockerfile

The Dockerfile explains how the Docker image is built.

It starts from Ubuntu, installs the tools needed by the script, copies in `system_report.sh`, makes it executable, and runs it as the default command.

Basic flow:

```text
Dockerfile → docker build → infra-monitor image → container runs system_report.sh
```

## Docker Compose

The Compose file is:

```text
docker/docker-compose.yml
```

Docker Compose lets me run the container from YAML instead of typing a massive `docker run` command every time.

From inside the `docker` folder:

```bash
docker compose up -d --build
docker compose ps
docker compose logs infra-monitor
docker compose down
```

## Volumes

The Compose file mounts the host logs folder into the container:

```yaml
volumes:
  - ../logs:/app/logs
```

This means:

```text
Host folder:      logs/
Container folder: /app/logs
```

The container writes logs to `/app/logs`, but they are saved in the host `logs/` folder, so they can survive even after the container stops.

That matters because this is a monitoring project, and losing logs would be not nice at all.

## Environment Variables

Runtime configuration is handled through `day9.env`.

Example values:

```env
CPU_WARN_THRESHOLD=70
MEMORY_WARN_THRESHOLD=70
DISK_WARN_THRESHOLD=70
INFRA_MONITOR_SYSTEM_LOG=/app/logs/day9-env-file.log
INFRA_MONITOR_ERROR_LOG=/app/logs/day9-error.log
```

Simple idea:

```text
Image                 → packaged application
Environment variables → runtime settings
```

This lets the same Docker image run with different thresholds, log paths, or settings.

Do NOT commit real AWS credentials or secrets.

## Current Workflow

From the project root:

```bash
cd docker
docker compose up -d --build
docker compose ps
docker compose logs infra-monitor
```

Check generated logs:

```bash
cd ..
tail -n 40 logs/day9-env-file.log
```

## Architecture

```text
AWS EC2 / Ubuntu VM
↓
Docker
↓
Docker Compose
↓
infra-monitor container
↓
system_report.sh
↓
persistent logs
```

## Why Docker Matters

Before Docker, the script depended more on the machine it was running on.

With Docker, the monitoring app is packaged into a repeatable container environment.

This makes `infra-monitor` easier to run on:

* Ubuntu VM
* AWS EC2
* Future cloud servers

The project is now a containerised system monitoring service.

Small Bash script has officially entered its Docker era.
