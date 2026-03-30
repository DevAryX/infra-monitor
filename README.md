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
- ☁️ Automatic upload of logs to AWS S3
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

Logs are automatically uploaded to an S3 bucket.

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
│   ├── resource-check.sh
│   └── system_report.sh
├── logs/
│   ├── system_report.log
│   ├── system_report_*.log
│   └── error.log
├── docs/
│   ├── cloud-notes.md
│   ├── ec2-startup-notes.md
│   ├── git-notes.md
│   └── log-notes.md  
├── proof
│   ├── feb_imgs
│   └── mar_imgs
│ 
├── .gitignore
├── README.md
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

## 🛣 Roadmap

Next improvements:

- Replace cron with **systemd service (Linux daemon)**
- Upload **rotated logs** to S3 (not just latest)
- Add **alerting system** (email / Discord)
- Compress old logs (`.gz`)
- Infrastructure as Code (Terraform)
- Monitoring stack (Prometheus + Grafana)

---

## 🧠 Philosophy

This project is intentionally built step-by-step.

Each stage reflects real learning, mistakes, debugging, and improvements, not just copying tutorials.

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

## ⚠️ Notes

- Logs are intentionally excluded from Git (`.gitignore`)
- This project is designed to be portable and reproducible
- Built and tested on AWS EC2 (Linux environment)

---

## 🔗 Author

GitHub: https://github.com/DevAryX

---

🚀 More features coming soon as the system evolves inshallah.
