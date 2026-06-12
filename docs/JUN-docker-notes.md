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

## Summary

Terraform builds the cloud server.

Docker packages the infra-monitor app so it can run more consistently.

This is the next step from “it works on my server” to “it can run properly anywhere Docker is installed.”
