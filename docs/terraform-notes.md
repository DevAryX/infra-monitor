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

