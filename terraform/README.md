# Terraform Infrastructure

This folder contains the Terraform setup for my `infra-monitor` project.

The main goal here is simple: instead of clicking around in the AWS Console, I want the infrastructure to be created from code.

This makes the setup easier to rebuild, understand, and improve over time.

## What This Terraform Setup Creates

Right now, this Terraform config creates:

* An EC2 instance for the infra-monitor project
* A Security Group for network access
* An SSH rule restricted to my own public IP
* An outbound rule so the instance can access the internet
* Outputs for useful details like the public IP and SSH command

The EC2 instance uses Amazon Linux 2023 and is created inside the default AWS VPC.

## Current Architecture

```text
Ubuntu VM
  ↓
Terraform CLI
  ↓
AWS Provider
  ↓
Default VPC
  ↓
Security Group
  ↓
EC2 Instance
  ↓
SSH Access
```

Terraform runs from my Ubuntu 22.04 VM inside VirtualBox on my Windows 11 PC.

So my Ubuntu VM is basically the control machine for managing AWS.

## Files Explained

### `main.tf`

This is the main Terraform file.

It defines the AWS provider, default VPC lookup, Amazon Linux 2023 AMI lookup, Security Group, SSH rule, outbound rule, and EC2 instance.

Basically, this is where most of the actual infrastructure is described.

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
ssh/infra-monitor-key.pem
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
ssh -i ssh/infra-monitor-key.pem ec2-user@PUBLIC_IP
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

Final May statement:

> I used Terraform to provision AWS infrastructure for my Linux monitoring project, making the cloud setup reproducible, documented, and easier to rebuild.

May phase done. Big target hit.


