# Infra Monitor

This is a Linux-based system monitoring and automation project, which i built step-by-step to learn real-world infrastructure and DevOps

This project started as a simple Bash script and is now turning into a small cloud-integrated monitoring pipeline.

---

## What This Project Does

This is now a **mini monitoring pipeline**.

### Features

* 📊 System health reporting for CPU, memory, disk, processes, and network
* 🕒 Automated execution using cron
* 📝 Structured logging to local log files
* ☁️ Optional AWS S3 log upload using environment variables
* ⚠️ Error handling for failed cloud uploads
* 🔄 Log rotation to prevent logs growing forever
* 🧠 Dynamic paths so the project is portable across systems
* 🚀 CI/CD deployment using GitHub Actions
* 🔐 GitHub Secrets for deployment credentials
* 📦 Automated Docker build and Compose validation

---

## Architecture Overview

This project now runs as a containerised monitoring service on AWS EC2.

The infrastructure is created with Terraform, the monitoring application is packaged with Docker, and Docker Compose is used to run the container on the EC2 instance.

Current architecture:

```text
Terraform
    ↓
AWS EC2 + Elastic IP
    ↓
Docker
    ↓
Docker Compose
    ↓
GitHub Actions CI/CD
    ↓
infra-monitor container
    ↓
Persistent logs
```

---

## How to Run Locally

Clone the repository:

```bash
git clone https://github.com/DevAryX/infra-monitor.git
cd infra-monitor
```

Make scripts executable:

```bash
chmod +x scripts/*.sh
```

Create a local environment file from the example:

```bash
cp .env.example ~/.infra-monitor.env
source ~/.infra-monitor.env
```

Run the monitoring script manually:

```bash
./scripts/system_report.sh
```

---

## Infrastructure Overview

This project currently runs on an AWS EC2 instance using Amazon Linux 2023.

The instance is deployed inside an AWS VPC and public subnet, with internet access provided through an Internet Gateway. SSH access is controlled using AWS Security Groups.

Current architecture:

```text
Ubuntu VM → Internet → AWS VPC → Public Subnet → EC2 Instance
```

A basic architecture diagram is available in:

```text
docs/architecture_diagram.png
```

---

## March 2026 Milestone

This phase focused on building a **production-style monitoring system**.

Main improvements:

* Automated monitoring using cron
* Persistent structured logging
* AWS S3 integration
* Basic failure handling
* Log rotation
* Resource safety

---

## April 2026 Infrastructure Improvements

April focused on making the project more realistic from a cloud and operations point of view.

Main improvements:

* Documented public vs private IPs
* Mapped the EC2 network path through VPC, subnet, route table, and Internet Gateway
* Restricted SSH access with Security Groups
* Added Linux firewall protection using `firewalld`
* Documented ports `22`, `80`, and `443`
* Reviewed AWS billing and cost risks
* Added environment-variable based configuration
* Improved logging format
* Added configurable log rotation
* Tested EC2 stop/start behaviour
* Checked cron after restart
* Split cron output and error logs
* Performed basic failure testing and recovery
* Consolidated networking notes

---

## May 2026 — Terraform Infrastructure as Code

May focused on moving the AWS setup from manual cloud setup to Terraform-based Infrastructure as Code.

Main improvements:

* Added a dedicated `terraform/` folder
* Created AWS infrastructure using Terraform instead of manual AWS Console setup
* Added an EC2 instance resource
* Added a Terraform-managed Security Group
* Restricted SSH access using a specific public IP `/32`
* Added outbound internet access for the instance
* Added variables for region, project name, environment, instance type, SSH CIDR, and key name
* Added safe example values using `terraform.tfvars.example`
* Added Terraform outputs for public IP, public DNS, instance ID, Security Group ID, and SSH command
* Tested SSH access using Terraform output values
* Destroyed and rebuilt the infrastructure using Terraform
* Proved the AWS setup is reproducible from code

This phase moved the project from manually created cloud infrastructure to a setup that can be created, destroyed, and rebuilt properly from Terraform files.

---

## June 2026 — Docker Containerisation

June focused on making the monitoring app portable using Docker.

Main improvements:

  * Added a dedicated `docker/` folder
  * Created a Dockerfile for the monitoring script
  * Built a custom `infra-monitor` Docker image
  * Ran the monitoring script inside a Docker container
  * Added persistent logs using Docker volume mounts
  * Added environment-variable based container configuration
  * Created a Docker Compose YAML file
  * Deployed the containerised monitoring service on AWS EC2
  * Documented the Docker setup in `docker/README.md`

This phase moved the project from a Bash script running directly on a server to a containerised monitoring service that can be run through Docker Compose.

---

## July 2026 — CI/CD with GitHub Actions

July focused on adding CI/CD so the project could move from manual deployment to automated deployment.

Main improvements:

* Added a GitHub Actions workflow in `.github/workflows/test.yml`
* Triggered the workflow on pushes to `main`
* Added manual workflow runs using `workflow_dispatch`
* Added Bash syntax checks for project scripts
* Added a Docker image build check
* Added Docker Compose validation
* Added GitHub Secrets for EC2 deployment values
* Used the EC2 Elastic IP as the stable deployment host
* Tested SSH from GitHub Actions into EC2
* Temporarily allowed the GitHub Actions runner IP through the Security Group during deployment
* Created an EC2 deployment script at `~/deploy-infra-monitor.sh`
* Added a repo copy of the deploy script at `scripts/deploy-infra-monitor.sh`
* Added safety checks to the deploy script
* Added timestamped deployment logs at `~/infra-monitor/logs/deploy.log`
* Triggered the EC2 deployment script from GitHub Actions

This phase moved the project from a containerised monitoring service to a CI/CD-enabled cloud service that can be checked, rebuilt, and redeployed through GitHub Actions.

---

## Cron Setup

Edit your crontab:

```bash
crontab -e
```

Example cron job:

```cron
*/5 * * * * /home/ec2-user/infra-monitor/scripts/system_report.sh >> /home/ec2-user/infra-monitor/logs/cron_stdout.log 2>> /home/ec2-user/infra-monitor/logs/cron_stderr.log
```

This runs the monitoring script every 5 minutes and separates normal cron output from cron errors.

---

## AWS S3 Integration

S3 upload is optional.

If `INFRA_MONITOR_S3_BUCKET` is not set, the script skips the upload cleanly.

Requirements:

* AWS CLI installed
* EC2 instance with an IAM role attached
* S3 permissions configured correctly

Manual test:

```bash
aws s3 cp logs/system_report.log s3://your-bucket-name/system_report.log
```

---

## Project Structure

```text
infra-monitor/
├── scripts/
│   ├── deploy-infra-monitor.sh
│   ├── resource_check.sh
│   └── system_report.sh
├── docs/
│   ├── APR-cloud-docs.md
│   ├── architecture_diagram.png
│   ├── cloud-notes.md
│   ├── cost-notes.md
│   ├── ec2-startup-notes.md
│   ├── git-notes.md
│   ├── log-notes.md
│   └── networking-notes.md
├── proof/
│   ├── feb_imgs/
│   ├── mar_imgs/
│   ├── apr_imgs/
│   └── may_imgs/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── README.md
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── README.md
├── logs/                 # generated locally, ignored by Git
├── .github/
│   └── workflows/
│       └── test.yml
├── .env.example
├── .gitignore
└── README.md
```

---

## What I’ve Learned

* Writing production-style Bash scripts
* Handling failures with safer script logic
* Building structured logging systems
* Using cron for automation
* Uploading logs to AWS S3
* Debugging real-world issues with paths, permissions, and cron environments
* Making scripts portable using environment variables
* Understanding cloud networking and EC2 security basics
* Building Docker images with Dockerfiles
* Running Bash scripts inside containers
* Using bind mounts for persistent container logs
* Passing runtime configuration through environment variables
* Running containers with Docker Compose
* Deploying a Docker Compose workload on AWS EC2
* Creating GitHub Actions workflows
* Running CI checks for Bash scripts
* Building Docker images in CI
* Validating Docker Compose in CI
* Using GitHub Secrets safely
* Deploying to EC2 through GitHub Actions
* Adding deployment safety checks and logs

---

## Roadmap

Completed phases:

- February 2026 — Git and GitHub foundations
- March 2026 — AWS EC2 monitoring pipeline
- April 2026 — Cloud polish, networking, logging, and cost awareness
- May 2026 — Terraform Infrastructure as Code
- June 2026 — Docker containerisation
- July 2026 — GitHub Actions CI/CD

Upcoming improvements:

- August 2026 — Prometheus, Grafana, and security improvements
- September 2026 — final portfolio polish

---

## Notes

* Logs are intentionally excluded from Git using `.gitignore`
* Real environment files are not committed
* `.env.example` shows the expected config structure
* This project is designed to be portable and reproducible
* Built and tested on AWS EC2 using Amazon Linux 2023

---

## Author

GitHub: https://github.com/DevAryX

---

More features coming soon as the system evolves, inshallah.
