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


## April Day 9 — Instance Cost Awareness

Today I looked at EC2 pricing and instance sizing.

For this project, On-Demand pricing makes the most sense because I am still building and testing the infrastructure. I do not need a long-term reserved setup yet.

I also checked the EC2 instance type and confirmed that a small burstable instance is enough for the current workload.

Detailed notes are saved in:

```text
docs/cost-notes.md
```

