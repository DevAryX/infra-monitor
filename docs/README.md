# Documentation Guide

This repository contains both current operational documentation and historical learning notes from each stage of the project.

## Current Source of Truth

- [Main project README](../README.md) — finished architecture, operation, security model and usage
- [Final verification](final-verification.md) — final technical audit and verified system state
- [Architecture diagram](architecture_diagram.png) — end-to-end infrastructure and monitoring design
- [Project retrospective](project-retrospective.md) — development journey, lessons, limitations and future improvements

## Operational Guides

- [Terraform infrastructure](../terraform/README.md)
- [Docker environment](../docker/README.md)
- [Monitoring stack](../monitoring/README.md)
- [Bootstrap notes](bootstrap-notes.md)
- [Bootstrap hardening](aug-bootstrap-hardening.md)

## Historical Learning Record

The following files preserve the development journey. Some describe earlier versions of the infrastructure that were later replaced or improved.

| Phase | Documentation |
|---|---|
| Git and Bash foundations | [Git notes](git-notes.md), [logging notes](log-notes.md) |
| Initial AWS deployment | [Cloud notes](cloud-notes.md), [EC2 startup notes](ec2-startup-notes.md) |
| Networking and cloud polish | [April cloud documentation](APR-cloud-docs.md), [networking notes](networking-notes.md), [cost notes](cost-notes.md) |
| Terraform | [May Terraform notes](MAY-terraform-notes.md) |
| Docker and YAML | [June Docker notes](JUN-docker-notes.md), [YAML notes](yaml-notes.md) |
| CI/CD | [July CI/CD notes](JUL-cicd-notes.md) |
| Monitoring and security | [August monitoring and security notes](AUG-monitoring-security-docs.md) |

When historical notes differ from the current README or operational guides, the current documentation is authoritative.
