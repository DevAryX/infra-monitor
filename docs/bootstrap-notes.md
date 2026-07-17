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


## Bootstrap Test Result

The bootstrap was tested by replacing the EC2 instance with Terraform:

```bash
terraform apply -replace=aws_instance.infra_monitor
```

After the new EC2 instance was created, the same Elastic IP was attached and SSH access worked using:

```bash
ssh -i ~/ssh/infra-monitor-key.pem ec2-user@EC2_ELASTIC_IP
```

Cloud-init completed successfully:

```bash
cloud-init status --wait
```

Result:

```text
status: done
```

The bootstrap log showed:

```text
Bootstrap completed successfully
```

The new EC2 instance automatically had:

```text
Git
Docker
Docker Buildx
Docker Compose
infra-monitor repository
logs directory
deployment script
correct ec2-user ownership
```

The deployment script also ran successfully:

```bash
bash ~/deploy-infra-monitor.sh
```

This rebuilt the Docker image, started the Docker Compose service, and wrote timestamped deployment output to:

```text
/home/ec2-user/infra-monitor/logs/deploy.log
```

## Issue Found and Fixed

The first bootstrap attempt failed because the script tried to install the full `curl` package on Amazon Linux 2023.

Amazon Linux 2023 already had `curl-minimal`, which conflicted with `curl`.

The failing install line was changed from:

```bash
dnf install -y git docker curl ca-certificates
```

to:

```bash
dnf install -y git docker ca-certificates
```

Then the script checks whether the `curl` command exists before trying to install anything else:

```bash
if ! command -v curl >/dev/null 2>&1; then
  dnf install -y curl-minimal
fi
```

This fixed the package conflict and allowed the bootstrap to complete successfully.

## Verification Commands

Useful commands for checking a newly bootstrapped EC2 instance:

```bash
cloud-init status --wait
sudo tail -n 120 /var/log/infra-monitor-bootstrap.log

ls -la ~/infra-monitor
ls -la ~/infra-monitor/logs
ls -la ~/deploy-infra-monitor.sh

git --version
docker --version
docker buildx version
docker compose version

bash ~/deploy-infra-monitor.sh
tail -n 80 ~/infra-monitor/logs/deploy.log
```


