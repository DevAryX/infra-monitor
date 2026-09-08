# Project Retrospective

## Overview

Infra Monitor began in February 2026 as a Bash script that generated a basic Linux system report.

Over the following months, it evolved into a reproducible AWS-hosted monitoring and automation platform using Terraform, Docker Compose, GitHub Actions, Prometheus, Grafana and IAM.

The final system can provision its infrastructure, configure a fresh EC2 instance, deploy the application, collect host and application metrics, restrict network access and verify its own health after deployment.

The project was developed from an Ubuntu 22.04 virtual machine running on a Windows 11 host. The Ubuntu VM acted as the main control environment for Git, Terraform, the AWS CLI and SSH access.

The purpose was not simply to collect as many tools as possible. Each new part was introduced to solve a limitation discovered in the previous version.

## The Original Problem

The original Bash script collected information such as CPU details, memory usage, disk usage, uptime, network interfaces and resource warnings.

That was useful locally, but it raised several larger questions:

- How could the script run on a real cloud server?
- How could the infrastructure be rebuilt consistently?
- How could the application run independently of the host setup?
- How could changes be tested and deployed automatically?
- How could system health be observed over time?
- How could access and AWS permissions be restricted?
- What would happen if the server or one of its services failed?

The rest of the project developed by answering those questions one stage at a time.

## Project Evolution

| Phase | Development |
|---|---|
| February 2026 | Built the Bash monitoring scripts and practised Git workflows, commits, merging, rebasing and conflict resolution |
| March 2026 | Deployed the project to an AWS EC2 instance and introduced logging and S3 report storage |
| April 2026 | Studied networking, Security Groups, host firewalls, environment variables and cloud cost awareness |
| May 2026 | Replaced manually created AWS resources with Terraform-managed infrastructure |
| June 2026 | Containerised the application and introduced Docker Compose |
| July 2026 | Built a GitHub Actions pipeline for validation, testing and automated EC2 deployment |
| August 2026 | Added Node Exporter, Prometheus, Grafana, custom metrics, IAM roles and failure testing |
| Post-August | Automated fresh-instance configuration using cloud-init and a hardened bootstrap process |
| September 2026 | Completed technical verification, architecture documentation and portfolio preparation |

## Major Lessons

### Linux and Bash

The project started with Linux fundamentals, but Bash eventually became part of a much larger automated system.

I learned how to work with processes, permissions, filesystems, logs, environment variables, exit codes, networking tools and service management.

I also learned that scripts used by automation must behave predictably. Clear exit codes, structured logging, input validation and error handling matter because another system may depend on the result.

The monitoring application writes its Prometheus metrics to a temporary file before moving the completed file into place. This prevents Node Exporter from reading partially written metric data.

That small implementation detail showed me how reliability can depend on understanding how different processes interact with the same files.

### Git and GitHub

Git began as a way to save versions of the Bash scripts, but it eventually became the source of truth for application code, infrastructure, monitoring configuration, dashboards and deployment automation.

I practised branches, merging, rebasing, conflict resolution and clean commit history during the early project stages.

Later, Git became part of the deployment design itself. The CI/CD workflow deploys the exact commit SHA that passed validation instead of assuming the latest commit on `main` is the correct version.

This taught me that version control is not only about storing code. It can also define exactly what version of a system should be running.

### AWS and Networking

Initially, using AWS meant manually launching an EC2 instance and connecting to it through SSH.

As the project developed, I learned how EC2, Security Groups, Elastic IPs, IAM roles, instance metadata, S3 and the default VPC interact.

I also learned the difference between making a service reachable and exposing it unnecessarily.

Grafana, Prometheus and Node Exporter do not require permanent public ingress. Grafana and Prometheus are accessed through authenticated SSH port forwarding, while Security Groups and `firewalld` restrict direct access.

This helped me understand that cloud infrastructure is not just a virtual server. It includes identity, networking, storage, access control and lifecycle management.

### Terraform

Terraform changed the infrastructure from something I configured manually into something that could be described, reviewed and recreated.

The configuration manages the EC2 instance, Security Group, Elastic IP, encrypted root storage, IAM role, policy, instance profile and bootstrap configuration.

One of the most important tests was deliberately replacing the EC2 instance.

The instance ID changed, but the Elastic IP remained stable and the monitoring platform rebuilt itself on the replacement server.

This demonstrated the difference between having infrastructure that currently works and having infrastructure that can be reproduced.

I also learned that infrastructure changes have consequences. A small-looking user-data change can cause instance replacement, so `terraform plan` must be reviewed rather than treated as a formality.

### Docker

Docker made the application portable, but it also introduced a monitoring challenge.

A normal container observes its own isolated environment. The purpose of Infra Monitor was to report the EC2 host, not only the container.

The final design uses selected host namespaces and a read-only host-root mount so the application can collect the required host information. At the same time, the container uses a read-only root filesystem, drops Linux capabilities and enables `no-new-privileges`.

This taught me that containerisation is not automatically secure or portable without understanding namespaces, mounts, permissions and runtime configuration.

I also learned that an `Exited (0)` container is not necessarily broken. Infra Monitor is intentionally a one-shot workload, while Node Exporter, Prometheus and Grafana remain running continuously.

### CI/CD

The first pipeline performed basic checks and deployed the project, but the finished workflow does considerably more.

It validates Bash syntax, builds the Docker image, validates Docker Compose and monitoring configuration, runs integration tests, deploys the exact tested commit and performs remote health checks.

The deployment job temporarily adds the GitHub Actions runner's public `/32` address to the EC2 Security Group and removes it afterwards.

A successful SSH connection is not considered a successful deployment. The remote health checker must verify the application, monitoring services, Prometheus targets, custom metrics and Grafana health.

This taught me that deployment automation should be treated as software. It needs controlled inputs, validation, failure handling and a clear definition of success.

### Monitoring and Observability

Before this project, I mainly thought of monitoring as viewing command output or reading logs.

The finished project helped me distinguish between:

- Reports that capture system state at one moment
- Logs that explain events and failures
- Metrics that can be measured over time
- Health checks that produce a clear pass or fail result
- Dashboards that help people understand trends and current state

Node Exporter provides standard Linux metrics, while the Bash application publishes project-specific metrics using the Node Exporter textfile collector.

Prometheus stores and queries those metrics, and Grafana presents them through a provisioned dashboard.

Failure testing was particularly useful. I deliberately stopped Node Exporter, observed Prometheus reporting the target as down and then verified recovery.

That provided stronger evidence than only testing the healthy state.

### Security and IAM

One of the largest lessons was that “it works” and “it works securely” are different achievements.

The project moved away from broad or stored AWS credentials and now uses an EC2 IAM role with temporary credentials delivered through IMDSv2.

The workload receives only the `s3:PutObject` permission required for its configured report object.

Successful access was tested, but denied actions were also tested. Bucket listing, writing to another object and unrelated EC2 API access were rejected.

Other security controls include:

- Trusted `/32` SSH ingress
- Temporary GitHub Actions runner ingress
- Private monitoring ports
- Host-level `firewalld`
- Encrypted root storage
- Ignored runtime configuration
- Grafana credentials stored outside the repository
- Pinned Docker tooling with checksum verification
- Bootstrap SHA256 verification
- Restricted container privileges

This taught me that security is usually created through multiple smaller controls rather than one setting.

## Important Turning Points

### The Container Was Monitoring the Wrong Environment

Containerising the Bash script initially risked reporting the container rather than the EC2 host.

Solving this required understanding Linux namespaces and mounts instead of treating Docker as a black box.

### Deployment Did Not Mean Reproducibility

By the end of July, a push to `main` could deploy automatically to the existing EC2 server.

However, replacing that server exposed a major weakness: the new instance did not automatically contain Git, Docker, the repository, runtime files or the monitoring stack.

That discovery led to the cloud-init and bootstrap implementation.

### A Green Deployment Needed a Health Gate

An SSH command completing successfully did not prove the monitoring platform was healthy.

Adding the reusable health checker changed deployment success from “the remote command ran” to “the complete system passed its operational checks.”

### Healthy-State Testing Was Not Enough

Stopping services, recreating containers, rebooting EC2 and replacing the instance revealed more about the architecture than repeatedly checking the normal dashboard.

This changed how I think about testing infrastructure.

## What I Would Do Differently

If I restarted the project, I would establish clearer documentation categories earlier so historical learning notes and current operational instructions were separated from the beginning.

I would also create the reusable health-check script earlier. It became useful for local testing, EC2 validation, bootstrap verification and CI/CD deployment gates.

Proof screenshots would use one naming convention from the start, and I would introduce automated bootstrapping earlier to reduce the amount of manual host configuration.

However, discovering these weaknesses gradually was also valuable. Each limitation gave me a practical reason to learn the next technology instead of adding tools without understanding why they were needed.

## Current Scope and Limitations

Infra Monitor is designed as a single-host learning and portfolio platform rather than a highly available production service.

Current limitations include:

- Terraform state is stored locally
- GitHub Actions deployment still uses SSH
- The platform depends on a single EC2 instance
- The configuration uses the existing AWS default VPC
- Alert notifications are not implemented
- Logs are not aggregated into a central search platform
- Grafana access requires an SSH tunnel
- There is only one deployment environment

These limitations do not prevent the current project from meeting its goal. They identify realistic directions the architecture could take if its requirements increased.

## Future Improvements

Future work should be driven by an actual requirement rather than adding technology only because it is popular.

### Near-Term Improvements

1. **Remote Terraform state**

   Move Terraform state to a protected remote backend with locking and versioning. This would improve recovery and make controlled collaboration possible.

2. **GitHub Actions AWS OIDC**

   Replace long-lived GitHub AWS credentials with short-lived role credentials obtained through OpenID Connect.

3. **Alerting**

   Add Alertmanager so important conditions can generate notifications rather than requiring someone to inspect Grafana manually.

4. **Automated infrastructure validation**

   Add Terraform security scanning, static analysis and automated infrastructure tests to the CI pipeline.

### Medium-Term Improvements

5. **Centralised logging**

   Collect application and host logs in a searchable platform so metrics and logs can be investigated together.

6. **Controlled HTTPS access**

   Introduce a reverse proxy, TLS and suitable authentication if the dashboard needs controlled browser access without an SSH tunnel.

7. **Reusable Terraform modules**

   Separate the infrastructure into modules if additional environments or repeated deployments are required.

8. **Multiple environments**

   Introduce development and production environments only when separate deployment lifecycles become useful.

### Long-Term Improvements

9. **Configuration management**

   Introduce a configuration-management tool if host configuration grows beyond what the current bootstrap can manage clearly.

10. **Container orchestration**

    Explore a platform such as Kubernetes only if the project grows into multiple long-running services that genuinely require scheduling, scaling and orchestration.

These are optional extensions. They are not unfinished requirements for the current version.

## Final Reflection

The most valuable part of Infra Monitor was not learning one individual tool. It was understanding how the tools connect.

A Bash script became a version-controlled application. The application moved to AWS. The infrastructure became reproducible through Terraform. Docker made the workload portable. GitHub Actions automated validation and deployment. Prometheus and Grafana made the system observable. IAM, network restrictions and hardened bootstrap logic improved its security.

The final result is a system I can provision, deploy, monitor, break, recover and explain.

The project also changed how I define completion. A system is not complete only because it runs once. It should be understandable, reproducible, testable, observable and appropriately secured.

Infra Monitor has reached that goal for its intended scope. Future work can extend it, but the core project is complete.
