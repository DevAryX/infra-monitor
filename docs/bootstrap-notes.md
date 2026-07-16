# EC2 Bootstrapping Notes

## Purpose

This document explains the post-July EC2 bootstrapping improvement.

The CI/CD pipeline worked, but the EC2 instance still needed manual setup after being replaced.

A new EC2 instance did not automatically have:

```text
Git
Docker
Docker Buildx
Docker Compose support
infra-monitor repo
logs directory
deployment script
correct file permissions
```

This meant the EC2 instance was not fully disposable yet.

## Goal

The goal of bootstrapping is to make a new EC2 instance prepare itself on first boot.

New flow:

```text
Terraform creates EC2
↓
EC2 runs user_data on first boot
↓
Git and Docker are installed
↓
Docker Buildx and Compose support are installed
↓
infra-monitor repo is cloned
↓
logs directory is created
↓
permissions are fixed for ec2-user
↓
deployment script is prepared
↓
GitHub Actions can deploy without manual EC2 setup
```

## Files Added

The bootstrap script is stored at:

```text
terraform/user_data.sh
```

Terraform passes it into the EC2 instance using:

```hcl
user_data = file("${path.module}/user_data.sh")
```

## Permissions Fix

The bootstrap script creates the logs directory and fixes ownership:

```bash
mkdir -p /home/ec2-user/infra-monitor/logs
chown -R ec2-user:ec2-user /home/ec2-user/infra-monitor
chmod -R u+rwX /home/ec2-user/infra-monitor/logs
```

This prevents future deployment logging permission issues.

## Important Notes

The EC2 instance is now more disposable, but these still need to stay stable:

```text
Elastic IP
Security Group
SSH key pair
Terraform state
GitHub Secrets
```

The Elastic IP keeps the `EC2_HOST` value stable.

The Security Group still controls SSH access, including the temporary GitHub Actions runner IP rule.

## Debugging

Bootstrap output can be checked on EC2 with:

```bash
sudo tail -n 100 /var/log/infra-monitor-bootstrap.log
sudo tail -n 100 /var/log/cloud-init-output.log
```

A successful bootstrap creates:

```text
/var/log/infra-monitor-bootstrap.done
```

## Local Validation

Before applying Terraform, run:

```bash
terraform fmt -recursive
bash -n terraform/user_data.sh
```

Then:

```bash
cd terraform
terraform validate
terraform plan
```

Important: adding `user_data_replace_on_change = true` may cause Terraform to replace the EC2 instance.

That is expected, but do not apply until ready.

Also remember: replacing EC2 deletes anything stored only on the old instance. The Elastic IP should survive, but local EC2 logs on the old root disk may not.

## Result

This makes the project more resilient because a replacement EC2 instance can prepare itself automatically instead of needing manual setup.

Basically, future EC2 replacements should be cleaner and easier and less painful.
