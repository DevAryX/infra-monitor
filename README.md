# Infra Monitor

A Linux-based system monitoring and automation project, built by me slowly to learn real-world infrastructure, version control, and cloud fundamentals.

This repository is designed to evolve over time, from local Linux scripts and humble beginnings to a fully cloud-deployed, containerised, and monitored system.

---

## Why this project exists

I wanted one long-term project instead of many small, disconnected tutorials.

The goal is to:
- Build strong Linux fundamentals
- Use Git and GitHub properly (branches, merges, conflicts)
- Gradually move from local scripts to cloud infrastructure
- Understand *why* tools like Docker, Terraform, and CI/CD exist

This project will continue to grow as I learn.

---

## Current features (February 2026)

- Advanced system health reporting script
- Resource usage checker (CPU & memory thresholds)
- Clean Git history with feature branches
- Documented merge vs rebase behaviour
- Experience resolving real merge conflicts

---

## How to run

Clone the repository:

```bash
git clone https://github.com/DevAryX/infra-monitor.git
cd infra-monitor
```

Make scripts executable:

```bash
chmod +x scripts/*.sh
```

Run the system report:

```bash
./scripts/system_report.sh
```

Run the resource checker:

```bash
./scripts/resource_check.sh
```
---

## What I’ve learned so far

Linux system inspection (CPU, memory, disk, processes, networking)

Writing readable and maintainable Bash scripts

Git fundamentals: commits, branches, merges, rebasing

How and why merge conflicts happen — and how to fix them

Using GitHub as a real collaboration tool, not just storage

---

## Roadmap

Planned future improvements:

Deploy scripts to a cloud VM (AWS EC2)

Infrastructure as Code using Terraform

Containerisation with Docker

CI/CD using GitHub Actions

Monitoring with Prometheus & Grafana

---

## Notes

This project is intentionally built step-by-step.
Each stage reflects what I understood at that time.


---

## February 2026 Milestone

This month focused on building strong Git and GitHub fundamentals using a single, evolving project.


Key outcomes:
- Wrote and refactored real Linux monitoring scripts
- Used feature branches for all new work
- Practiced merges, rebasing, and conflict resolution
- Learning how to recover from mistakes without panic
- Treated GitHub as a workflow, not just storage


Future months will build directly on this Foundation Insha'Allah.
