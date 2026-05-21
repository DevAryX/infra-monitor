## April Day 1 — Public vs Private IPs

### My Current Setup

My local environment uses:
- Windows 11 as the host machine
- Ubuntu 22.04 LTS running inside Oracle VM VirtualBox
- VirtualBox network mode: NAT
- AWS EC2 instance running Amazon Linux 2023

The Ubuntu VM is used to SSH into the EC2 instance and manage the infra-monitor project.

### Public IP

A public IP is reachable from the internet.
In this project, the EC2 public IP is used to connect to the server using SSH.

Example connection flow:

```
Ubuntu VM → Internet → EC2 Public IP → AWS Security Group → EC2 Instance
```
