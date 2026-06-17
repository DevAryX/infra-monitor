# Docker Notes

## What Docker Is

Docker is used to package and run applications inside containers.

A container includes the app, its files, dependencies, environment variables, and the command needed to run it.

The main point is portability. If Docker is installed, the same container should run on different machines without me constantly fixing setup issues.

## Containers vs Virtual Machines

A VM is like a full computer inside another computer.

A container is more like a packaged app environment.

Simple version:

```text
VM        → full machine
Container → isolated app environment
```

## Why Docker Matters

Without Docker, a project might work on one machine but break on another because of paths, packages, or environment differences.

Docker helps avoid that by packaging the app environment into an image.

## How Docker Fits Into infra-monitor

The project started as a Bash script.

Then it moved onto AWS EC2.

Then Terraform made the infrastructure reproducible.

Now Docker is being added to make the actual app more portable.

Current flow:

```text
Terraform
↓
EC2
↓
Docker
↓
infra-monitor system report
```

## Key Terms

### Image

A blueprint for a container.

### Container

A running version of an image.

### Dockerfile

A file that tells Docker how to build the image.

### Docker Compose

A YAML-based way to define and run containers.


Terraform builds the cloud server.

Docker packages the infra-monitor app so it can run more consistently.

This is the next step from “it works on my server” to “it can run properly anywhere Docker is installed.”


## Day 2 — Docker Installation

Today I installed Docker inside my Ubuntu 22.04 VM.

This VM is my main development/control machine, so Docker will be tested here first before moving it onto EC2 later.

Installed packages:

* `docker-ce`
* `docker-ce-cli`
* `containerd.io`
* `docker-buildx-plugin`
* `docker-compose-plugin`

Current setup:

```text
Windows 11 host
↓
Ubuntu 22.04 VM
↓
SSH into AWS EC2
↓
Manage infra-monitor
```

For now, Docker runs locally inside the Ubuntu VM.

Later, Docker will also be installed on the EC2 instance so `infra-monitor` can run as a containerised service in the cloud.

Verification commands:

```bash
docker --version
docker compose version
docker ps
```

### Result

Docker Engine is installed, running, and Docker Compose is available through the modern `docker compose` command.


## Day 3 — First Container

Today I ran my first Docker container using:

```bash
docker run hello-world
```

This tested the basic Docker workflow.

Docker pulled the `hello-world` image, created a container from it, ran it, printed the success message, and then stopped.

Commands used:

```bash
docker run hello-world
docker images
docker ps
docker ps -a
docker container prune
```

### Image vs Container

An image is the saved template.

A container is an instance created from that image.

Simple version:

```text
Image     → template
Container → running or stopped instance
```

The `hello-world` container exits quickly because its only job is to print a message and stop.

That is why `docker ps` does not show it afterwards. To see stopped containers, use:

```bash
docker ps -a
```

### Result

Running `hello-world` proved Docker is working properly inside my Ubuntu VM.

It also showed the basic container lifecycle:

```text
Pull image → Create container → Run container → Exit
```

This is the same basic flow I will later use for the `infra-monitor` container.



## Day 4 — Container Exploration

Today I went inside an Ubuntu container and explored what it actually looks like.

I started an interactive container with:

```bash
docker run -it ubuntu bash
```

The `-it` part gives me a usable terminal inside the container.

Inside the container, I checked:

```bash
pwd
ls
cat /etc/os-release
```

The prompt changed to something like:

```text
root@container-id:/#
```

That showed I was inside the container, not directly on my Ubuntu VM.

### What I Noticed

The container has its own Linux filesystem with folders like:

```text
bin
etc
home
root
usr
var
```

It feels like a small Linux environment, but it is not a full VM.

Some tools like `git` and `nano` were missing, which makes sense because container images are usually kept minimal.

### Temporary Container Test

I created a test file inside the container:

```bash
echo "hello from inside the container" > container-test.txt
```

Then I exited and started a new Ubuntu container.

The file was gone.

That showed me that containers are temporary unless data is stored properly.

Simple lesson:

```text
Image     → reusable blueprint
Container → temporary running instance
Volume    → keeps data persistent
```

### Result

Today made containers feel more real.

I could see that a container is its own isolated environment, but anything important, like future infra-monitor logs, will need to be stored properly using volumes.


## Day 5 — Dockerfile Basics

Today I created my first custom Docker image using a Dockerfile.

The Dockerfile was saved at:

```text
docker/Dockerfile
```

I built the image with:

```bash
docker build -t infra-monitor-day5 -f docker/Dockerfile .
```

Then I ran it with:

```bash
docker run --rm infra-monitor-day5
```

### Dockerfile Instructions Learned

`FROM` chooses the base image.

For this project, I used:

```dockerfile
FROM ubuntu:22.04
```

`WORKDIR` sets the working folder inside the image:

```dockerfile
WORKDIR /app
```

`COPY` copies files from my project into the image:

```dockerfile
COPY docker/day5-message.txt ./day5-message.txt
```

`RUN` happens while the image is being built:

```dockerfile
RUN echo "Docker image built successfully for infra-monitor Day 5" > build-info.txt
```

`CMD` runs when the container starts:

```dockerfile
CMD ["bash", "-c", "echo 'Custom infra-monitor Docker image is running'; echo; cat day5-message.txt; echo; cat build-info.txt"]
```

Simple difference:

```text
RUN → build time
CMD → container run time
```

### Build Context

The build command ended with a dot:

```bash
docker build -t infra-monitor-day5 -f docker/Dockerfile .
```

The dot means Docker uses the current folder as the build context.

Because I ran it from the repo root, Docker could access files like:

```text
docker/day5-message.txt
```

### Result

Okay now I know how a Dockerfile turns project files and instructions into a custom image.

Basic flow:

```text
Dockerfile → docker build → Image → docker run → Container output
```

This is the same process I’ll use next to containerise the real `infra-monitor` script.




## Day 6 — Containerising `system_report.sh`

Today I containerised the real `infra-monitor` Bash script.

Instead of just running a test message, the Docker image now copies in `system_report.sh` and runs it inside a container.

Image built with:

```bash
docker build -t infra-monitor -f docker/Dockerfile .
```

Container run with:

```bash
docker run --rm infra-monitor
```

The Dockerfile copies the script into:

```text
/app/scripts/system_report.sh
```

Then `CMD` runs it automatically when the container starts.

Main Dockerfile instructions used:

```dockerfile
FROM ubuntu:22.04
WORKDIR /app
COPY scripts/system_report.sh ./scripts/system_report.sh
CMD ["./scripts/system_report.sh"]
```

I also added environment variables so the script uses container paths instead of relying on my normal machine paths:

```dockerfile
ENV INFRA_MONITOR_HOME=/app
ENV INFRA_MONITOR_LOG_DIR=/app/logs
ENV INFRA_MONITOR_SYSTEM_LOG=/app/logs/system_report.log
ENV INFRA_MONITOR_ERROR_LOG=/app/logs/error.log
```

### Result

Today was the first proper step where `infra-monitor` became containerised.

Current flow:

```text
Dockerfile → docker build → infra-monitor image → docker run → system_report.sh runs in container
```

(IVE BEEN TOLD) this is a big step because the actual monitoring script is now packaged inside Docker, not just tested with a basic container.


## Day 7 — Docker Build and Run Workflow (Long day)

Today I practised the Docker build and run workflow properly.

I rebuilt the image with:

```bash
docker build -t infra-monitor -f docker/Dockerfile .
```

Then I ran the container with a specific name:

```bash
docker run --name infra-monitor-day7 infra-monitor
```

After the script finished, the container exited.

`docker ps` did not show it because that only shows running containers.

To see stopped containers as well, I used:

```bash
docker ps -a
```

I checked the container output with:

```bash
docker logs infra-monitor-day7
```

Then I removed the stopped container with:

```bash
docker rm infra-monitor-day7
```

### Key Commands

```text
docker build   → build an image
docker images  → list images
docker run     → create and start a container
docker ps      → show running containers
docker ps -a   → show all containers
docker logs    → view container output
docker stop    → stop a running container
docker rm      → remove a stopped container
docker rmi     → remove an image
```

### What I Learned

A container can be given a name using `--name`, but container names must be unique.

If a stopped container still exists with that name, Docker will not let me reuse it until I remove the old one.

Important lesson:

```text
Stopped does not mean deleted.
```

For quick tests, this is cleaner:

```bash
docker run --rm infra-monitor
```

The `--rm` flag removes the container automatically after it exits, so I do not end up with loads of stopped containers sitting around.

Simple cleanup difference:

```text
docker stop → stops a running container
docker rm   → removes a stopped container
docker rmi  → removes an image
```

### Result

Day 7 made the Docker workflow feel more normal, like I understood it more.

I now understand how to build the image, run a named container, check logs, remove old containers, and avoid clutter using `--rm`.


## Day 8 — Docker Volumes and Persistent Logs

Today I worked on making container logs survive after the container is removed.

The problem was simple:

```text
Container removed → logs inside container removed too
```

That isnt useful for a monitoring project, cuz logs actually matter.

To fix this, I created a logs folder on the host:

```bash
mkdir -p logs
```

Then I ran the container with a bind mount:

```bash
docker run --rm \
  --mount type=bind,source="$(pwd)/logs",target=/app/logs \
  infra-monitor
```

This connects:

```text
Host folder:      ./logs
Container folder: /app/logs
```

Because the Dockerfile sets the log directory to `/app/logs`, the script writes logs into the mounted host folder.

So even when the container is removed, the logs stay in my project folder. yessir

### Bind Mounts

A bind mount connects a folder from my machine to a folder inside the container.

For `infra-monitor`, this is useful because I can see the logs directly from the Ubuntu VM without digging around inside Docker.

### Named Volumes

I also tested a named Docker volume:

```bash
docker volume create infra-monitor-logs
```

Then ran the container with:

```bash
docker run --rm \
  --mount type=volume,source=infra-monitor-logs,target=/app/logs \
  infra-monitor
```

Simple difference:

```text
Bind mount   → folder chosen by me
Named volume → storage managed by Docker
```

For this project, bind mounts are better during development because the logs are easy to see in the repo.

### Result

On Day 8 I figured that containers should be disposable, but important data should live outside the container.

Current flow:

```text
infra-monitor container
↓
writes logs to /app/logs
↓
/app/logs is mounted to ./logs
↓
logs survive after the container is removed
```


## Day 9 — Docker Environment Variables

Today I tested controlling the `infra-monitor` container using environment variables.

First, I ran the container with values passed directly into the command:

```bash
docker run --rm \
  -e CPU_THRESHOLD=70 \
  -e MEMORY_THRESHOLD=70 \
  -e DISK_THRESHOLD=70 \
  --mount type=bind,source="$(pwd)/logs",target=/app/logs \
  infra-monitor
```

This showed that the same Docker image can be reused with different settings

### Environment File

I also created an environment file:

```text
docker/day9.env
```

Example values:

```env
CPU_THRESHOLD=70
MEMORY_THRESHOLD=70
DISK_THRESHOLD=70
INFRA_MONITOR_SYSTEM_LOG=/app/logs/day9-env-file.log
INFRA_MONITOR_ERROR_LOG=/app/logs/day9-error.log
```

Then I ran the container using the env file:

```bash
docker run --rm \
  --env-file docker/day9.env \
  --mount type=bind,source="$(pwd)/logs",target=/app/logs \
  infra-monitor
```

### What I Learned

Environment variables let me change how the container behaves without rebuilding the image.

Simple idea:

```text
Image                 → packaged application
Environment variables → runtime settings
```

So the same `infra-monitor` image can run with different thresholds, log files, or settings depending on where it is being used.


ALSO: Environment variables are fine for normal config, but secrets like AWS keys should NOT be committed to GitHub or baked into the Docker image.

### Result

On day 9 I made the Docker setup more flexible.

The container can now be configured at runtime instead of needing a new image every time I want to change a setting. Yallah habibi


## Day 10 — Yaml stuff

all day 10 stuff has been noted down in `yaml-notes.md`.


## Day 11 — Docker Compose

Today I started running `infra-monitor` using Docker Compose.

A Compose file was created at:

```text
docker/docker-compose.yml
```

The file defines the `infra-monitor` service:

```yaml
services:
  infra-monitor:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    image: infra-monitor
    container_name: infra-monitor-compose
    env_file:
      - day9.env
    volumes:
      - ../logs:/app/logs
```

### What I Learned

The main concept today was `services`.

In Docker Compose, a service is bakisly the container setup written in YAML

For this project, the service is called:

```text
infra-monitor
```

This tells Compose to:

* build the image
* load the env file
* mount the logs folder
* run the container

Commands used:

```bash
cd docker
docker compose config
docker compose up --build
docker compose logs infra-monitor
docker compose down
```

Before Compose, I had to run a long `docker run` command with env files and mounts.

Now the same setup can be started with:

```bash
docker compose up --build
```

### Result

Day 11 was a big Docker milestone. Alhumdulillah.

The project now flows like this:

```text
Dockerfile → Docker image → docker-compose.yml → Compose-managed container
```

This makes the setup cleaner because I do not need to keep typing long `docker run` commands every time.
