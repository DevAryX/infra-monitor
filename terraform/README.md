# Terraform Infrastructure

This folder contains the Terraform setup for my `infra-monitor` project.

The main goal here is simple: instead of clicking around in the AWS Console, I want the infrastructure to be created from code.

This makes the setup easier to rebuild, understand, and improve over time.

## What This Terraform Setup Creates

The Terraform configuration manages the AWS infrastructure required by `infra-monitor`.

It currently provisions and configures:

- An Amazon Linux 2023 EC2 instance
- A stable Elastic IP address
- A Security Group with restricted SSH ingress
- Outbound internet access
- A Terraform-managed IAM role
- A least-privilege S3 upload policy
- An EC2 instance profile
- An encrypted gp3 root EBS volume
- IMDSv2-only instance metadata access
- SHA-verified Terraform user data
- A deterministic `bootstrap.sh` process
- `firewalld` configuration
- Docker and pinned Docker CLI plugins
- Runtime environment creation
- Grafana credential generation
- Docker Compose deployment
- Monitoring and IAM verification

The EC2 host is intentionally disposable.

Terraform can replace the instance while the Elastic IP remains stable, and the hardened bootstrap reconstructs the application and monitoring stack automatically.

## Current Architecture

```
Ubuntu VM
    │
    ↓
Terraform
    │
    ├── Security Group
    ├── Elastic IP
    ├── IAM Role + Policy
    ├── Instance Profile
    └── encrypted gp3 EBS
    │
    ↓
Amazon Linux 2023 EC2
    │
    ↓
SHA-verified user data
    │
    ↓
terraform/bootstrap.sh
    │
    ├── firewalld
    ├── Docker
    ├── pinned Buildx
    ├── pinned Compose
    ├── runtime configuration
    └── Grafana credentials
    │
    ↓
Docker Compose monitoring stack
```

Terraform is run from the Ubuntu VM, which acts as the infrastructure control machine.

## Files Explained

### `main.tf`

This is the main infrastructure definition.

It defines the AWS provider, Amazon Linux 2023 AMI lookup, Security Group rules, Elastic IP, EC2 instance, encrypted gp3 root volume, IMDSv2 settings, hardened user-data rendering, and the Elastic IP association.

The EC2 user data is rendered from `user_data.sh.tftpl`, while Terraform calculates the SHA256 of `bootstrap.sh` so the instance verifies the bootstrap script before executing it.

### `iam.tf`

Defines the EC2 IAM role, least-privilege S3 upload policy, policy attachment, and instance profile.

The workload uses temporary EC2 role credentials instead of long-lived AWS access keys.

### `user_data.sh.tftpl`

A small Terraform-rendered first-stage launcher.

It installs the minimum required dependencies, clones or synchronises the repository, verifies the SHA256 of `bootstrap.sh`, passes runtime values into the bootstrap process, and executes the verified script.

### `bootstrap.sh`

Contains the deterministic fresh-instance bootstrap.

It installs and configures host packages, `firewalld`, Docker, pinned Docker Buildx and Compose plugins, runtime configuration, Grafana credentials, the Compose stack, IAM verification, and final monitoring health checks.

### `variables.tf`

This file defines the input variables used by Terraform.

Current variables include:

* `aws_region`
* `project_name`
* `environment`
* `instance_type`
* `allowed_ssh_cidr`
* `key_name`

This makes the config easier to change without editing everything manually inside `main.tf`.

### `terraform.tfvars.example`

This is the safe example file.

It shows what values are needed, but only uses placeholder values, so it is fine to commit to GitHub.

### `terraform.tfvars`

This is my real local values file.

It should not be committed because it can contain personal setup details like my public IP or AWS key pair name.

### `outputs.tf`

This file defines useful output values after deployment.

Current outputs include:

* EC2 instance ID
* Public IP address
* Public DNS name
* Security Group ID
* SSH command

This saves me from digging through the AWS Console just to find the connection details.

### `.terraform.lock.hcl`

This locks the Terraform provider versions.

It helps keep Terraform behaviour consistent across machines.

## Prerequisites

Before running this setup, I need:

* Terraform installed
* AWS CLI installed
* AWS CLI configured
* An existing AWS EC2 key pair
* The matching `.pem` private key saved locally

Expected SSH key path:

```bash
~/ssh/infra-monitor-key.pem
```

The private key should never be committed to GitHub.

## Example `terraform.tfvars`

Create a local `terraform.tfvars` file using the example file as a guide:

```hcl
aws_region       = "eu-west-2"
project_name     = "infra-monitor"
environment      = "learning"
instance_type    = "t3.micro"
key_name         = "your-existing-key-pair-name"
allowed_ssh_cidr = "your-public-ip/32"
```

The `allowed_ssh_cidr` should normally be my current public IP with `/32` at the end.

Example:

```hcl
allowed_ssh_cidr = "86.xxx.xxx.xxx/32"
```

The `/32` keeps SSH restricted to one exact public IP instead of opening it to everyone.

## Deploying the Infrastructure

From the repo root:

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

When Terraform asks for confirmation, type:

```text
yes
```

After deployment, Terraform shows useful outputs like the public IP, instance ID, and SSH command.

## Connecting to the EC2 Instance

From the repo root, I can use the SSH command output from Terraform:

```bash
cd ~/infra-monitor
$(cd terraform && terraform output -raw ssh_command)
```

Or connect manually:

```bash
ssh -i ~/ssh/infra-monitor-key.pem ec2-user@PUBLIC_IP
```

Useful checks once connected:

```bash
uname -a
cat /etc/os-release
whoami
hostname
```

## Destroying the Infrastructure

To remove the infrastructure created by Terraform:

```bash
cd terraform
terraform plan -destroy
terraform destroy
```

When Terraform asks for confirmation, type:

```text
yes
```

This removes the Terraform-managed EC2 instance, Security Group rules, and Security Group.

## Rebuilding the Infrastructure

After destroying the setup, I can rebuild it again with:

```bash
terraform plan
terraform apply
```

This is the main point of Infrastructure as Code.

If the infrastructure can be destroyed and rebuilt from config files, then the setup is not just manually created once. It is actually reproducible.

## Safety Notes

Do not commit:

* `terraform.tfvars`
* `terraform.tfstate`
* `terraform.tfstate.backup`
* `.terraform/`
* `.pem` private key files
* AWS credentials

Only safe config, examples, and documentation should go on GitHub.

## Current Status

The Terraform setup can currently:

* Create a Security Group
* Create an EC2 instance
* Restrict SSH to my public IP
* Output the EC2 connection details
* Destroy and rebuild the infrastructure from code

This was a big step because the project is no longer just running on manually created cloud infrastructure.

Terraform can now build the base AWS setup properly.

---

## May 2026 Completion Summary

The May Terraform phase is officially complete.

This month, the project moved from manual AWS setup to proper Infrastructure as Code.

Terraform can now:

* Create an EC2 instance
* Create a Security Group
* Restrict SSH using my public IP `/32`
* Add outbound internet access
* Use variables for cleaner config
* Output connection details like the public IP and SSH command
* Destroy and rebuild the infrastructure from code
* Keep the Terraform setup documented properly

This means the AWS setup is no longer something I just clicked together once in the Console.

It can now be rebuilt from code, which is the whole point.

> I used Terraform to provision AWS infrastructure for my Linux monitoring project, making the cloud setup reproducible, documented, and easier to rebuild.

May phase done.

---

## EC2 IAM Role

Slight update to Terraform here,

The EC2 workload now gets AWS permissions through a Terraform-managed IAM role and instance profile.

Permission flow:

```
EC2

IAM Instance Profile

infra-monitor-ec2-role

infra-monitor-s3-upload policy

Amazon S3
```

The custom policy follows least privilege.

Right now, the monitoring app only needs:

```
s3:PutObject
```

So the policy only allows upload to the configured system report object, not full random S3 access.

This means the EC2 instance does not need long-lived AWS access keys for the workload.

AWS gives the instance temporary role credentials through the EC2 metadata service and rotates them automatically.

### Tested

I tested that:

```
intended report upload works
bucket listing is denied
uploading to the wrong object key is denied
unrelated EC2 API access is denied
```

So the app gets the exact permission it needs and nothing extra.

Much cleaner than leaving AWS keys sitting around.
