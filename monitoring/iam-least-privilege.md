# EC2 IAM Least-Privilege Test

## Purpose

This test checks that the EC2 workload only has the AWS permissions it actually needs.

The monitoring app can optionally upload `system_report.log` to S3.

But the EC2 server does **not** need long-lived AWS access keys sitting on it.

Instead, it uses an IAM role attached through an EC2 instance profile.

## Required Permission

The app only needs this AWS action:

```
s3:PutObject
```

The policy is restricted to the configured bucket and exact system report object key.

So it can upload the report, but it does not get random full S3 access.

## IAM Flow

```
EC2
↓
IAM Instance Profile
↓
infra-monitor-ec2-role
↓
infra-monitor-s3-upload policy
↓
s3:PutObject
↓
configured S3 report object
```

## Temporary Credentials

The app does not store AWS keys.

The AWS CLI gets temporary credentials from the EC2 IAM role through the Instance Metadata Service.

AWS manages and rotates those credentials automatically.

Much better than leaving access keys on the server like a security horror story.

## Verification

I checked the container identity with:

```
aws sts get-caller-identity
```

It showed the workload was using:

```
infra-monitor-ec2-role
```

I tested that:

```
system report upload works
bucket listing is denied
uploading to the wrong S3 key is denied
unrelated EC2 API access is denied
```

## Result

The EC2 workload now has only the AWS permission it needs for the current S3 upload feature.

No long-lived workload AWS credentials are needed on the server.

so bakisly a cleaner and safer setup.
