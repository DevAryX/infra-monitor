# Networking Notes

## Overview

This file explains the networking setup used in my infra-monitor project.

The project is managed from an Ubuntu VM running in VirtualBox on my Windows 11 PC. The VM connects to an AWS EC2 instance running Amazon Linux 2023.

## Network Flow

```text
Windows 11 PC
↓
Ubuntu VM - VirtualBox NAT
↓
Home Public IP
↓
Internet
↓
EC2 Public IPv4
↓
AWS Security Group
↓
EC2 Private IPv4 inside VPC
↓
Amazon Linux 2023
```

## Public and Private IPs

The Ubuntu VM has a private NAT IP inside VirtualBox.

When it connects to AWS, the connection comes from my home public IP.

The EC2 instance has:

* Public IPv4 for SSH access
* Private IPv4 inside the AWS VPC

Useful checks:

```bash
hostname -I
curl -s https://checkip.amazonaws.com
```

## VPC, Subnet and Internet Gateway

The EC2 instance runs inside an AWS VPC and public subnet.

For internet access, the subnet needs a route through an Internet Gateway:

```text
0.0.0.0/0 → Internet Gateway
```

This is what allows the instance to be reachable from outside AWS.

## Security Groups

A Security Group acts like the AWS firewall.

For this project, SSH is restricted to my own public IP:

```text
SSH TCP 22 → My Public IP /32
```

This is safer than opening SSH to everyone with:

```text
0.0.0.0/0
```

## SSH and Firewall Flow

SSH uses port `22`.

```text
Ubuntu VM
↓
Internet
↓
EC2 Public IPv4:22
↓
Security Group
↓
firewalld
↓
sshd
```

The EC2 instance also uses `firewalld` as a Linux host firewall.

This gives two layers of protection:

```text
Security Group → firewalld → SSH service
```

## Ports

Current port setup:

```text
22  → SSH open only to my public IP
80  → HTTP closed
443 → HTTPS closed
```

Ports `80` and `443` are closed because I am not running a website yet.

So if someone types the EC2 public IP into a browser, nothing should load. That is expected.

## EC2 Stop/Start Behaviour

After stopping and starting the EC2 instance, the public IPv4 can change.

If SSH stops working after a restart, I need to check the new public IP in the EC2 console and update the SSH command.

An Elastic IP could make the public IP stay the same, but I am not using one yet because this is still a learning project and I am staying cost-aware.

## Summary

The EC2 instance is set up so SSH is the only required inbound service.

SSH is restricted to my own public IP, and the Linux firewall also allows SSH.

Ports `80` and `443` stay closed because no web server is running.

This keeps the server usable without exposing more than needed.
