# Logging Strategy (EC2 + Cloud)

## Why Logs Matter
Logs record what the system is doing.  
They help with debugging, monitoring, and diagnosing failures.

If something breaks, logs are the first place to look.

---

## Append vs Overwrite
Using `>>` appends to a file.  
Using `>` overwrites the file.

Appending keeps history.  
Overwriting deletes previous data.

For monitoring, preserving history is usually important.

---

## Why Structured Output Is Important
Structured logs (timestamps, status labels, clear formatting) make logs readable and searchable.

Example:  
`[2026-03-20 14:02] STATUS: OK`

Clear structure makes debugging and automation easier.

---

# EC2 Logging Setup (What I Actually Built)

## The Setup (Simple Explanation)
Basically:

I have my main machine → inside that I have a VM → inside that I’m running an EC2 instance.

So EC2 is basically like:

👉 a computer inside my computer

And I’m working directly on that.

---

## My Workflow
What I did:

- Uploaded my GitHub repo to EC2  
- Ran my system report script  
- Set up cron to run it every 5 minutes  
- Output goes into a log file  

So it looks like:

```
8:20  
8:25  
8:30  
8:35  
...
```

That’s my log history building up.

---

## The Problem (Very Important)
Right now:

👉 logs only exist on the EC2 instance

If:

- The instance crashes  
- I terminate it  
- Disk gets corrupted  

👉 everything is gone  

No logs  
No history  
No idea what happened  

That’s bad.

---

# Shipping Logs to the Cloud (S3)

## What We Do Instead
We don’t just keep logs locally.

We push them to the cloud.

So even if EC2 dies:

👉 logs are still safe

---

## What Is S3 (Simple Explanation)
S3 is basically:

👉 a storage bucket in the cloud  

You can think of it like:

"Google Drive but for servers"

It’s:

- very durable  
- cheap  
- used everywhere in industry  

People store:

- logs  
- backups  
- datasets  
- websites  

---

## What I Did

### Step 1 — Create Bucket
I created a bucket like:

```
infra-monitor-ary-logs-2026blahblah
```

Important:

👉 bucket name must be globally unique  

Also used same region as EC2.

---

### Step 2 — AWS CLI on EC2
Checked if AWS CLI is installed:

```
aws --version
```

If not:

```
sudo dnf install awscli -y
```

---

### Step 3 — Give EC2 Permission (VERY IMPORTANT)

By default:

👉 EC2 CANNOT access S3

So I created an IAM role:

- Service: EC2  
- Permission: AmazonS3FullAccess (for now)  

Attached it to my instance.

This is better than using access keys (more secure).

---

### Step 4 — Test Connection

```
aws s3 ls
```

If bucket shows up:

👉 connection works

---

### Step 5 — Upload Log

Manual test:

```
aws s3 cp ~/infra-monitor/logs/system_report.log s3://your-bucket-name/
```

Then I checked S3:

👉 file was there  

So now EC2 → S3 works.

---

# 🔁 Automation (The Important Bit)

Inside my script, I added:

```
aws s3 cp $LOG_FILE s3://your-bucket-name/system_report.log
```

Now every time cron runs:

- script runs  
- log updates  
- log uploads to S3  

So flow becomes:

```
Cron → Script → Log → S3 upload
```

Fully automated.

---

# What This Actually Is (Big Picture)

This isn’t just “a script”

This is:

```
Local Dev
↓
GitHub
↓
Cloud Server (EC2)
↓
Automated Monitoring (cron)
↓
Cloud Storage Backup (S3)
```

👉 this is actual infrastructure / DevOps flow

---

# 🚀 Production Improvements (Making It Proper)

Now we fix real problems.

---

## 🛡 1 — Stop Silent Failures

At top of script:

```
set -e
```

What this does:

👉 if something fails → script stops immediately  

Without this:

- something fails  
- script continues  
- logs look fine  
- but system is broken  

That’s dangerous.

---

## 🛡 2 — Log S3 Failures

Instead of blindly uploading:

```
if ! aws s3 cp $LOG_FILE s3://your-bucket-name/system_report.log; then
    echo "S3 upload failed at $(date)" >> ../logs/error.log
fi
```

Now:

👉 if upload fails → it gets logged  

So you can actually see issues.

---

## 🛡 3 — Prevent Logs Growing Forever

Right now:

👉 log file grows infinitely  

That’s bad (disk fills up eventually).

So I added basic rotation:

```
MAX_SIZE=50000

FILE_SIZE=$(stat -c%s "$LOG_FILE")

if [ "$FILE_SIZE" -gt "$MAX_SIZE" ]; then
    mv $LOG_FILE "../logs/system_report_$(date +%F_%H-%M-%S).log"
    touch $LOG_FILE
fi
```

What this does:

- checks file size  
- if too big → renames it  
- creates new log file  

So you keep history + control size.

---

# 🔍 Checking Logs

```
ls -lh ~/infra-monitor/logs/
```

You’ll see:

- system_report.log  
- old rotated logs  
- error.log (if anything failed)

---

# 🧠 Final Understanding

This is NOT just logging anymore.

You’ve built:

- a scheduled monitoring system  
- with persistent logs  
- with cloud backup  
- with error tracking  
- with log rotation  

👉 this is literally entry-level DevOps / cloud engineering

