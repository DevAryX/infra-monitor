## April — Networking and Security

This week was about understanding how my Ubuntu VM actually connects to my EC2 instance, and how to make that access safer.

## Day 1 — Public vs Private IPs

My setup is:

```text
Windows 11 → Ubuntu VM → Internet → EC2 Instance
```

The EC2 public IP is what lets me connect to the server using SSH.

```text
Ubuntu VM → EC2 Public IP → Security Group → EC2 Instance
```

## Day 2 — VPC, Subnet and Internet Gateway

My EC2 instance sits inside an AWS network, not just randomly on the internet.

```text
AWS VPC → Public Subnet → EC2 Instance
```

The Internet Gateway allows the VPC to connect to the internet.

The important route is:

```text
0.0.0.0/0 → Internet Gateway
```

This helped me understand that SSH depends on more than just the public IP.

## Day 3 — Security Groups

A Security Group is basically the AWS firewall for my EC2 instance.

SSH is only allowed from my own public IP:

```text
SSH → Port 22 → My Public IP /32
```

This is safer than opening SSH to everyone:

```text
0.0.0.0/0
```

## Day 4 — SSH Access Restricted

I restricted SSH so only my public IP can reach port `22`.

```text
Ubuntu VM → Home Public IP → Internet → Security Group → EC2
```

I tested it with:

```bash
nc -vz EC2_PUBLIC_IP 22
```

And confirmed SSH still works:

```bash
ssh -i learning/ssh/infra-monitor-key.pem ec2-user@EC2_PUBLIC_IP
```

## Day 5 — Host Firewall

I added another firewall layer inside the EC2 instance using `firewalld`.

```text
Internet → Security Group → firewalld → SSH
```

Commands used:

```bash
sudo dnf install firewalld -y
sudo firewall-offline-cmd --zone=public --add-service=ssh
sudo firewall-offline-cmd --set-default-zone=public
sudo systemctl enable --now firewalld
sudo firewall-cmd --list-all
```

This gives the instance cloud-level and Linux-level protection.

## Day 6 — Ports 22, 80 and 443

Ports decide which service traffic goes to.

```text
22  → SSH
80  → HTTP
443 → HTTPS
```

Right now, I only need SSH.

```text
22  → Open only to my public IP
80  → Closed
443 → Closed
```

Commands used:

```bash
sudo ss -tuln
sudo firewall-cmd --list-all

nc -vz EC2_PUBLIC_IP 22
nc -vz EC2_PUBLIC_IP 80
nc -vz EC2_PUBLIC_IP 443
```

## Day 7 — Week 1 Reflection

Today was mainly a recap day.

I tested what happens when I try to access the EC2 public IP through a browser. Since I am not running a web server yet, ports `80` and `443` do not respond, which is expected.

SSH still works because port `22` is open only to my public IP.

```text
22  → SSH allowed
80  → HTTP closed
443 → HTTPS closed
```

This confirmed that the server is only exposing what it actually needs right now.


## April Day 8 — Cost Awareness

Today I checked AWS Billing and Cost Management to see what parts of my setup could create charges.

The main things I checked were:

* EC2 running time
* EBS storage
* S3 storage
* Data transfer
* Forecasted monthly cost

Detailed notes are saved in:

```text
docs/cost-notes.md
```

This matters because cloud infrastructure is not just about getting things working. It also needs to be controlled properly so costs do not build up in the background.


## April Day 9 — Instance Cost Awareness

Today I looked at EC2 pricing and instance sizing.

For this project, On-Demand pricing makes the most sense because I am still building and testing the infrastructure. I do not need a long-term reserved setup yet.

I also checked the EC2 instance type and confirmed that a small burstable instance is enough for the current workload.

Detailed notes are saved in:

```text
docs/cost-notes.md
```

# Environment Variable Notes

## April Day 10 — Linux Environment Variables

Today I worked with Linux environment variables.

Environment variables let scripts use values from outside the code instead of hardcoding everything.

This makes the project easier to move between my Ubuntu VM, EC2, or a future Docker setup.

### Commands Used

```bash
export TEST_NAME="infra-monitor"
echo $TEST_NAME

source ~/.infra-monitor.env
source ~/.bashrc
```

### Project Env File

I created a project environment file:

```text
~/.infra-monitor.env
```

This stores settings like:

* Project path
* Log directory
* System log path
* Error log path
* CPU threshold
* Memory threshold
* Optional S3 bucket name

Example:

```bash
export INFRA_MONITOR_HOME="$HOME/infra-monitor"
export INFRA_MONITOR_LOG_DIR="$HOME/infra-monitor/logs"
export INFRA_MONITOR_CPU_THRESHOLD="80"
export INFRA_MONITOR_MEMORY_THRESHOLD="80"
```

### Auto Loading

I added this to `.bashrc` so the variables load automatically:

```bash
if [ -f "$HOME/.infra-monitor.env" ]; then
    source "$HOME/.infra-monitor.env"
fi
```

### GitHub Safety

The real environment file should not be pushed to GitHub.

Instead, I can include a safe example file:

```text
.env.example
```

## April Day 11 — Script Refactor Using Environment Variables

Today I refactored the monitoring script so it uses environment variables instead of hardcoded values.

The script can now read settings like:

```text
INFRA_MONITOR_LOG_DIR
INFRA_MONITOR_SYSTEM_LOG
INFRA_MONITOR_ERROR_LOG
INFRA_MONITOR_CPU_THRESHOLD
INFRA_MONITOR_MEMORY_THRESHOLD
INFRA_MONITOR_DISK_THRESHOLD
INFRA_MONITOR_S3_BUCKET
```

### Why This Matters

This separates the script from the config.

The script handles the logic, while the environment file controls paths, thresholds, and S3 settings.

This makes the project easier to run on:

* Ubuntu VM
* Amazon Linux EC2
* Future Docker setup
* Future CI/CD setup

### Cron Note

Cron does not always load the same environment as my normal terminal.

To make the script more reliable, it loads the project env file directly:

```bash
if [ -f "$HOME/.infra-monitor.env" ]; then
    source "$HOME/.infra-monitor.env"
fi
```

## April Day 12 — Improved Logging Format

Today I cleaned up the log format in the monitoring script.

The logs now show each report in a clearer block, with details like:

* Timestamp
* Hostname
* CPU usage
* Memory usage
* Disk usage
* Thresholds
* Status checks
* S3 upload result

Example structure:

```text
==================================================
[YYYY-MM-DD HH:MM:SS UTC] System Health Report
Hostname: example-host

CPU Usage: 12%
Memory Usage: 46%
Disk Usage: 18%

Thresholds:
CPU: 80%
Memory: 80%
Disk: 85%

Status:
CPU OK
Memory OK
Disk OK

S3 Upload: Success
==================================================
```

I also added cleaner error logging so errors are written in a consistent format:

```text
[YYYY-MM-DD HH:MM:SS UTC] ERROR: message
```

This makes the logs way easier to read, especially when the script runs again and again through automation.


## April Day 13 — Log Rotation

Today I added log rotation to stop the log files from growing forever.

Since the monitoring script can run again and again, the logs need a size limit.

The max log size is controlled with:

```text
INFRA_MONITOR_MAX_LOG_SIZE
```

If it is not set, the script uses:

```text
50000 bytes
```

When a log gets too big, it gets renamed with a timestamp and a fresh log file is created.

Example:

```text
system_report_2026-04-13_15-20-44.log
```

The same rotation function can be used for both logs:

```bash
rotate_log_file "$LOG_FILE" "system report" "$MAX_SIZE"
rotate_log_file "$ERROR_LOG" "error" "$MAX_SIZE"
```

I also cleaned up the S3 logging logic. Since S3 is optional right now, skipping upload is not treated as an error.

### Testing

I tested it by making the log file too large:

```bash
truncate -s 60000 logs/system_report.log
./scripts/system_report.sh
ls -lh logs/
```
This confirmed the old log was archived and a new one was created.



## April Day 15 — EC2 Stop and Start Behaviour

Today I looked at what happens when an EC2 instance is stopped and started again.

This matters because some parts stay the same, but some details can change.

### Reboot vs Stop vs Terminate

* **Reboot**: restarts the instance
* **Stop**: shuts it down but keeps the EBS storage
* **Terminate**: deletes the instance

### What Stays

After stopping and starting the instance, these should still be there:

* Project files
* Logs on disk
* Installed packages
* Cron jobs
* Security Group
* `firewalld` setup
* EBS volume

### What Can Change

The public IPv4 address can change after a stop/start.

So this may stop working:

```bash
ssh -i learning/ssh/infra-monitor-key.pem ec2-user@OLD_PUBLIC_IP
```

The fix is to copy the new public IPv4 address from the EC2 console.

### Elastic IP Note

An Elastic IP gives a stable public IP.

I am not using one yet because this project is still in development and I am keeping costs controlled.

### Commands Used

```bash
hostname -I
curl -s https://checkip.amazonaws.com
ls -la ~/infra-monitor
crontab -l
sudo firewall-cmd --list-all
```

## April Day 16 — EC2 Restart Recovery Test

Today I stopped and started my EC2 instance to check if the project still worked after a restart.

This was basically a recovery test.

### What I Checked

Before and after the restart, I checked:

```bash
hostname -I
curl -s https://checkip.amazonaws.com
crontab -l
sudo systemctl status crond --no-pager
sudo systemctl status firewalld --no-pager
```

After the instance came back online, I checked the new public IPv4 address because it can change after a stop/start.

### What Survived

The main setup was still there:

* Project files
* Scripts
* Logs
* Environment file
* Cron setup
* `firewalld` rules
* Security Group rules

### Script Test

```bash
cd ~/infra-monitor
source ~/.infra-monitor.env
bash -n scripts/system_report.sh
./scripts/system_report.sh
tail -n 40 logs/system_report.log
```

The script still ran properly after the restart.

This confirmed that the project can survive an EC2 stop/start.

The main thing to watch is the public IP, because if it changes, the SSH command needs updating.


## April Day 17 — Cron Output and Error Logging

Today I cleaned up the cron logging setup.

The goal was to make automated runs easier to debug.

Cron can behave differently from a normal terminal, so I made the cron job use full paths and separate log files.

### Cron Command

```cron
*/5 * * * * /home/ec2-user/infra-monitor/scripts/system_report.sh >> /home/ec2-user/infra-monitor/logs/cron_stdout.log 2>> /home/ec2-user/infra-monitor/logs/cron_stderr.log
```

Hourly version:

```cron
0 * * * * /home/ec2-user/infra-monitor/scripts/system_report.sh >> /home/ec2-user/infra-monitor/logs/cron_stdout.log 2>> /home/ec2-user/infra-monitor/logs/cron_stderr.log
```

### Log Files

```text
system_report.log → main report
error.log         → script errors
cron_stdout.log   → normal cron output
cron_stderr.log   → cron/shell errors
```

### Commands Used

```bash
sudo systemctl status crond --no-pager
crontab -l
sudo journalctl -u crond --since "30 minutes ago" --no-pager

tail -n 20 logs/cron_stdout.log
tail -n 20 logs/cron_stderr.log
tail -n 40 logs/system_report.log
```
This makes cron easier to troubleshoot.

If the script works manually but fails through cron, I now have separate logs to see what actually went wrong.


## April Day 18 — Basic Failure Testing

Today I tested how the monitoring script handles failure.

The goal was to make sure errors can be captured and the script can recover after something goes wrong.

### Failure Test

I forced the script to use a restricted log path under `/root`, which the `ec2-user` account cannot write to.

```bash
HOME=/tmp/infra-monitor-failure \
INFRA_MONITOR_LOG_DIR="/root/infra-monitor-denied" \
INFRA_MONITOR_SYSTEM_LOG="/root/infra-monitor-denied/system_report.log" \
INFRA_MONITOR_ERROR_LOG="/root/infra-monitor-denied/error.log" \
./scripts/system_report.sh >> logs/failure_test_stdout.log 2>> logs/failure_test_stderr.log \
|| echo "[$(date)] Expected failure captured during log path test" >> logs/failure_test_stderr.log
```

### What This Tested

* Permission failure handling
* `stdout` and `stderr` logging
* Manual recovery
* Whether errors are easy to trace

### Recovery Test

After the failure test, I reloaded the normal environment:

```bash
source ~/.infra-monitor.env
```

Then I ran the script again:

```bash
./scripts/system_report.sh >> logs/recovery_stdout.log 2>> logs/recovery_stderr.log
```

The script worked again and generated a normal report.

### Cron Check

```bash
crontab -l
sudo systemctl status crond --no-pager
```

This confirmed that the script can fail in a controlled way, log the issue, and recover after the correct settings are restored.


Cron Check
crontab -l
sudo systemctl status crond --no-pager

This confirmed that the script can fail in a controlled way, log the issue, and recover after the correct settings are restored.

## April Day 19 — Networking Notes

Today I created a dedicated networking notes file:

```text
docs/networking-notes.md
```

This file brings the main networking topics into one place, including:

* Public and private IPs
* Ubuntu VM NAT
* VPC and subnet structure
* Internet Gateway
* Security Groups
* SSH restricted with `/32`
* `firewalld`
* Ports `22`, `80`, and `443`
* EC2 stop/start public IP behaviour

This gives the project one clear place for the networking side of the setup instead of having the notes spread everywhere.

--- 

## April Day 20 — Final Polish

### Goal

Today I completed the final polish for the April cloud polish and networking phase.

The aim was to make the repository match the actual current state of the project and prepare it for the next stage.

### What Was Updated

I reviewed and updated:

- README project description
- Current feature list
- Project structure
- Security posture
- Configuration notes
- Documentation index
- Roadmap
- April infrastructure summary

### Why This Matters

A project is not only judged by whether it works.

It also needs to be understandable to someone viewing it for the first time.

The README should explain what the project does, how it is structured, what has been learned, and what will be improved next.

### April Summary

April focused on cloud infrastructure understanding and operational thinking.

The main areas covered were:

- AWS EC2 networking
- Public and private IPs
- VPCs and subnets
- Internet Gateway behaviour
- Security Groups
- SSH hardening
- Host firewall configuration
- Cost awareness
- Environment variables
- Structured logging
- Log rotation
- Cron reliability
- EC2 restart testing
- Basic failure testing
- Networking documentation

### Day 20 Summary

Today turned the April work into a cleaner portfolio-ready state.

The project now has stronger documentation, a more accurate README, and a clearer explanation of the infrastructure decisions made during April.
=======

## April Day 14 — Repository Cleanup

Today I cleaned up and reviewed the repo.

This was not about adding a new feature. It was more about making sure the project stays organised, safe, and easy to understand.

### What I Checked

* Folder structure
* Scripts
* Docs
* Proof screenshots
* `.gitignore`
* `.env.example`
* Log exclusions
* Environment file safety
* Script permissions
* Bash syntax

### Why This Matters

As the project grows, the structure matters more.

A working script is good, but a clean repo makes it easier to debug, explain, and show as a portfolio project.

### Summary

Today was a maintenance day.

The repo is now cleaner and ready for the next part of April, where the focus moves into cron reliability, infrastructure behaviour, and failure testing.

