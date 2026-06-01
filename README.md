# Infra Monitor

A Linux-based system monitoring and automation project, built step-by-step to learn real-world infrastructure, DevOps workflows, and cloud engineering.

This project started as a simple Bash script and is now turning into a small cloud-integrated monitoring pipeline.

---

## What This Project Does

This is no longer just a local script. It is a **mini monitoring pipeline**.

### Features

* 📊 System health reporting for CPU, memory, disk, processes, and network
* 🕒 Automated execution using cron
* 📝 Structured logging to local log files
* ☁️ Optional AWS S3 log upload using environment variables
* ⚠️ Error handling for failed cloud uploads
* 🔄 Log rotation to prevent logs growing forever
* 🧠 Dynamic paths so the project is portable across systems

---

## Architecture Overview

```text
Cron
 ↓
Bash Monitoring Script
 ↓
Local Log File
 ↓
Optional S3 Upload
 ↓
Rotated Logs
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
│   └── apr_imgs/
├── logs/                 # generated locally, ignored by Git
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

This marked the shift from **learning scripts** to **building systems**.

---

## Roadmap

Upcoming improvements:

* May 2026 — Terraform infrastructure as code
* June 2026 — Docker containerisation
* July 2026 — GitHub Actions CI/CD
* August 2026 — Prometheus, Grafana, and security improvements
* September 2026 — final portfolio polish

Possible technical upgrades:

* Replace cron with a systemd timer or service
* Compress rotated logs
* Upload rotated logs to S3
* Add alerting
* Add dashboard-based monitoring

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
