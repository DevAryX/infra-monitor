# Infra Monitor

A Linux-based system monitoring and automation project, built step-by-step to learn real-world infrastructure, DevOps workflows, and cloud engineering.

This project evolves from simple Bash scripts into a fully automated, cloud-integrated monitoring system.

---

## What this project does (Current State)

This is no longer just a local script, its a **mini monitoring pipeline**.

### Features:

- 📊 System health reporting (CPU, memory, disk, processes, network)
- 🕒 Automated execution using cron (runs every 5 minutes)
- 📝 Persistent logging to structured log files
- ☁️ Optional AWS S3 log upload using environment variables
- ⚠️ Error handling for failed cloud uploads
- 🔄 Log rotation to prevent disk overuse
- 🧠 Dynamic paths (portable across systems, no hardcoding)

---

## Architecture Overview

```
Cron (every 5 minutes)
        ↓
Bash Monitoring Script
        ↓
Local Log File (logs/system_report.log)
        ↓
S3 Upload (AWS Cloud Storage)
        ↓
Rotated Logs (timestamped history)
```

---

## How to run locally

Clone the repository:

```bash
git clone https://github.com/DevAryX/infra-monitor.git
cd infra-monitor
```

Make scripts executable:

```bash
chmod +x scripts/*.sh
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
docs/architecture-diagram.png
```

---


## ⚙️ Cron Setup (Automation)

Edit your crontab:

```bash
crontab -e
```

Add:

```bash
*/5 * * * * /bin/bash /full/path/to/infra-monitor/scripts/system_report.sh
```

This runs the monitoring system every 5 minutes.

---

## ☁️ AWS S3 Integration

S3 upload is supported as an optional feature. If `INFRA_MONITOR_S3_BUCKET` is not set, the script skips S3 upload cleanly.

Requirements:

- AWS CLI installed
- EC2 instance with IAM role attached (S3 permissions)

Manual test:

```bash
aws s3 cp logs/system_report.log s3://your-bucket-name/system_report.log
```

---

## 📂 Project Structure

```
infra-monitor/
├── scripts/
│   ├── resource_check.sh
│   └── system_report.sh
├── logs/
│   ├── system_report.log
│   ├── system_report_*.log
│   └── error.log
├── docs/
│   ├── cloud-notes.md
│   ├── ec2-startup-notes.md
│   ├── git-notes.md
│   ├── log-notes.md
│   ├── APR-cloud-docs.md
│   ├── architecture_diagram.png
│   ├── log-notes.md
│   └── networking-notes.md
├── proof/
│   ├── feb_imgs/
│   ├── mar_imgs/
│   └── apr_imgs/
│ 
├── .gitignore
├── .env.example
└── README.md
```

---

## What I’ve learned

- Writing production-style Bash scripts
- Handling failures using `set -e`
- Designing reliable logging systems
- Understanding cron and automation
- Building cloud pipelines using AWS S3
- Debugging real-world issues (paths, cron environments, permissions)
- Writing portable scripts using dynamic paths

---

## Roadmap

Upcoming improvements:

- May 2026 — Terraform infrastructure as code
- June 2026 — Docker containerisation
- July 2026 — GitHub Actions CI/CD
- August 2026 — Prometheus, Grafana, and security improvements
- September 2026 — final portfolio polish

Possible technical upgrades:

- Replace cron with a systemd timer or service
- Compress rotated logs
- Upload rotated logs to S3
- Add alerting
- Add dashboard-based monitoring

---


## 📅 March 2026 Milestone

This phase focused on building a **production-style monitoring system**:

- Automated monitoring using cron
- Persistent structured logging
- Cloud integration with AWS S3
- Basic failure handling and observability
- Log rotation and resource safety

This marks the transition from **learning scripts → building systems**.

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

## ⚠️ Notes

- Logs are intentionally excluded from Git (`.gitignore`)
- This project is designed to be portable and reproducible
- Built and tested on AWS EC2 (Linux environment)

---

## 🔗 Author

GitHub: https://github.com/DevAryX

---

More features coming soon as the system evolves inshallah.
