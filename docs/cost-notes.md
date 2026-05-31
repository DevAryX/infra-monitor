# Cost Notes

## April Day 8 — AWS Billing Dashboard

Today I checked the AWS Billing Dashboard to understand what parts of this project could cost money.

Cloud resources are not just technical. If something is left running, it can still create charges.

### What I Checked

* Current month charges
* EC2 costs
* S3 costs
* Data transfer
* Forecasted cost
* Any unexpected charges

### Main Cost Areas

```text
EC2        → costs while running
EBS        → storage can still cost even if EC2 is stopped
S3         → stores logs and backups
Data out   → traffic leaving AWS
Elastic IP → can cost if unused
```

### Cost Habits

To avoid random charges, I should:

* Stop EC2 when I am not using it
* Keep logs small and rotated
* Check S3 usage
* Avoid running services I do not need
* Check the Billing Dashboard regularly
* Set budget alerts where possible


## April Day 9 — On-Demand vs Reserved Instances

Today I looked at EC2 pricing and instance sizing.

### On-Demand

On-Demand makes the most sense for this project right now.

The infra-monitor setup is still a learning project, so I need flexibility more than a long-term discount.

### Reserved Instances

Reserved Instances are better for workloads that run for a long time and stay predictable.

They are not worth it for this project yet because the instance might change, stop, or only run when I need it.

### Instance Size

The current workload is still light:

* SSH access
* Monitoring scripts
* Logs
* Cron jobs
* S3 uploads

So a small burstable instance like `t2.micro` or `t3.micro` is enough for now.

### Commands Used

```bash
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
http://169.254.169.254/latest/meta-data/instance-type

nproc
free -h
df -h
uptime
```


