# Terraform Notes

## May 2026 Focus

May focuses on Terraform and Infrastructure as Code.

The goal is to stop relying on manual AWS clicking and start building infrastructure from reusable config files.

## What Is Infrastructure as Code?

Infrastructure as Code means managing cloud resources using code instead of manually setting everything up in the AWS Console.

Instead of clicking around to create an EC2 instance, Security Group, or network rule, the setup is written in Terraform files.

This makes the infrastructure easier to repeat, review, rebuild, and version control.

## Why Terraform?

Manual setup is fine at the start, but it gets messy quickly.

Problems with manual AWS setup:

* Easy to forget settings
* Hard to rebuild the same setup
* More chance of mistakes
* No clear history of changes
* Not very scalable

Terraform makes the setup more controlled and repeatable.

## Key Terraform Ideas

```text
Provider  → lets Terraform talk to AWS
Resource  → something Terraform creates
State     → tracks what Terraform has created
```

Examples of resources for this project:

```text
aws_instance
aws_security_group
```

Terraform commands I will be using:

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

## Current Setup

I am running Terraform from my Ubuntu VM inside VirtualBox on my Windows 11 PC.

The workflow is:

```text
Windows 11 PC
→ Ubuntu VM
→ Terraform + AWS CLI
→ AWS
→ EC2 Instance
→ SSH into EC2
```

Terraform will create the AWS infrastructure, then SSH will be used to manage the EC2 instance and run the infra-monitor scripts.

## May Goal

By the end of this phase, I want the project to create AWS infrastructure from code.

The target outcome is simple:

```text
Terraform creates the cloud infrastructure.
infra-monitor runs on the created EC2 instance.
```

This takes the project from manual cloud setup to proper Infrastructure as Code.

---

## Day 2 — Installing Terraform

Terraform was installed inside my Ubuntu 22.04 VirtualBox VM.

This VM is my control machine, so Terraform will run from here to manage AWS infrastructure.

I installed Terraform using the official HashiCorp APT repository.

Main steps:

* Updated apt packages
* Added HashiCorp’s GPG key
* Added the HashiCorp APT repository
* Installed Terraform with `apt`
* Checked it with `terraform version`

Useful commands introduced:

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

### Result

Terraform is now installed and ready to use from my Ubuntu VM.


## Day 3 — Terraform Basics

Today I created the first Terraform config file for the project:

```text
terraform/main.tf
```

This file sets up the basics Terraform needs before it can work with AWS.

It includes:

* Terraform settings
* Required AWS provider
* Terraform version requirement
* AWS region set to `eu-west-2`

The AWS provider tells Terraform which cloud platform to talk to and which region to use.

Example:

```hcl
provider "aws" {
  region = "eu-west-2"
}
```

This means Terraform will use the London AWS region.

## Day 4 — Connecting Terraform to AWS

Today I connected my Ubuntu VM to AWS so Terraform can manage cloud infrastructure from my control machine.

The workflow is:

```text
Windows 11 PC
→ Ubuntu VM
→ AWS CLI
→ Terraform
→ AWS Provider
→ AWS Resources
```

Commands used:

```bash
aws --version
aws configure
aws sts get-caller-identity

terraform init
terraform validate
terraform fmt
terraform plan
```

`aws sts get-caller-identity` confirmed that the AWS CLI was logged in properly.

`terraform init` downloaded the AWS provider and prepared the Terraform folder.

`terraform validate` confirmed the config was valid.

No infrastructure was created today.

### Result

Terraform can now connect to AWS from my Ubuntu VM and initialise successfully.


## Day 5 — First Terraform Resource: Security Group

Today I created my first AWS resource using Terraform.

The main resource was a Security Group for the future EC2 instance.

Created:

* `aws_security_group.infra_monitor_sg`
* SSH inbound rule
* All outbound traffic rule

The Security Group works like a firewall.

SSH is allowed on port `22`, but only from my current public IP. This is safer than opening SSH to everyone.

Commands used:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
terraform state list
```

### Result

* Terraform resources create real AWS infrastructure
* Security Groups control inbound and outbound traffic
* `terraform plan` should be checked before `apply`
* Terraform state tracks what Terraform created

Terraform successfully created the first Security Group for the infra-monitor project.


## Day 6 — Creating an EC2 Instance with Terraform

Today I created an EC2 instance using Terraform.

This was the first actual cloud server in the project created from code.

Added:

* Amazon Linux 2023 AMI lookup
* `key_name` variable
* `aws_instance.infra_monitor`

The AMI is loaded dynamically from AWS SSM instead of hardcoding an AMI ID. This keeps the config cleaner and stuff.

The instance uses:

* Amazon Linux 2023
* `t3.micro`
* Existing EC2 key pair
* Terraform Security Group
* Public IP for SSH

Commands used:

```bash
aws ec2 describe-key-pairs
terraform fmt
terraform validate
terraform plan
terraform apply
terraform state list
terraform state show aws_instance.infra_monitor
```

### Result

Terraform successfully created an Amazon Linux 2023 EC2 instance for infra-monitor. 



## Day 7 — Terraform Variables

Today I refactored the Terraform config to use variables.

Created:

* `variables.tf`
* `terraform.tfvars.example`
* local `terraform.tfvars`

The real `terraform.tfvars` file stays local and is not pushed to GitHub.

Variables added:

* `aws_region`
* `project_name`
* `environment`
* `instance_type`
* `allowed_ssh_cidr`
* `key_name`

Now the config uses values like:

```hcl
region        = var.aws_region
instance_type = var.instance_type
key_name      = var.key_name
```

Tags also use variables:

```hcl
Project     = var.project_name
Environment = var.environment
```

### now what happens

Variables make Terraform configs cleaner and easier to reuse.

`variables.tf` defines what values are needed.

`terraform.tfvars` stores my real local values.

`terraform.tfvars.example` shows the safe structure for GitHub.

The Terraform setup is now more reusable and less hardcoded.

## Day 8 — Terraform Outputs

Today I added Terraform outputs so useful details show after deployment.

Created:

* `outputs.tf`

Outputs added:

* `instance_id`
* `public_ip`
* `public_dns`
* `security_group_id`
* `ssh_command`

Before this, I had to dig through Terraform state to find things like the EC2 public IP.

Now Terraform shows the important details directly after `terraform apply`.

Commands used:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
terraform output -raw public_ip
terraform output -raw ssh_command
```

### Result

Terraform now shows the EC2 ID, public IP, public DNS, Security Group ID, and SSH command after deployment.

## Day 9 — SSH Test Using Terraform Output

Today was a proper milestone.

I used the SSH command generated by Terraform to connect into the EC2 instance that Terraform created.

Updated:

* `outputs.tf`
* `ssh_command` output
* SSH key path: `ssh/infra-monitor-key.pem`

Commands used:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output -raw ssh_command

chmod 400 ssh/infra-monitor-key.pem
ssh -i ssh/infra-monitor-key.pem ec2-user@PUBLIC_IP

uname -a
cat /etc/os-release
whoami
hostname
```

### What I Learned

* Terraform outputs can be used after deployment, not just for display
* The public IP can be pulled straight from Terraform
* SSH needs the correct key, username, Security Group, and public IP
* The `.pem` key needs safe permissions
* The EC2 instance created by Terraform is actually reachable and usable

### Result

I successfully SSH’d into the Terraform-created EC2 instance.

This felt like I properly hit the target, because Terraform was not  just creating resources on paper. I could actually connect to the server and prove the infrastructure worked end to end.



## Day 10 — Terraform Destroy and Rebuild Test

Today was a maddd one.

I tested if the infra-monitor AWS setup could be fully destroyed and rebuilt using Terraform.

This was the moment where Infrastructure as Code properly started to make sense, because the goal was not just to create an EC2 instance once. The goal was to prove I could delete it and bring it back from code. frickin insane.

Commands used:

```bash
terraform output
terraform output -raw instance_id
terraform output -raw public_ip
terraform plan -destroy
terraform destroy
terraform state list

aws ec2 describe-instances
aws ec2 describe-security-groups

terraform plan
terraform apply
terraform output -raw ssh_command

ssh -i ssh/infra-monitor-key.pem ec2-user@PUBLIC_IP
uname -a
cat /etc/os-release
```

### What I Did

First, I recorded the current EC2 details.

Then I ran:

```bash
terraform plan -destroy
```

This showed me what Terraform was about to remove before actually deleting anything.

After that, I ran:

```bash
terraform destroy
```

Terraform removed the EC2 instance and Security Group it had created.

Then I rebuilt everything nonchalantly again with:

```bash
terraform apply
```

After the rebuild, I used the Terraform SSH output and connected back into the new EC2 instance.

### What I Learned

* `terraform destroy` removes infrastructure tracked in Terraform state
* `terraform plan -destroy` lets me preview the deletion first
* Rebuilt infrastructure can get a new instance ID and public IP
* Terraform outputs make the new setup easier to use
* Infrastructure as Code means the setup can actually be recreated, not just manually built once

### Result

The infra-monitor AWS infrastructure was successfully destroyed and rebuilt using Terraform.
This felt like a proper target hit moment, because I proved the setup was reproducible. I could delete the server, rebuild it from code, and SSH back into it again. That is when Terraform started feeling real. What a Day.

