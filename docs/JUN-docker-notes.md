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

