# CI/CD Notes

## What CI/CD Means

CI/CD is about automatically checking, building, and deploying code after changes are pushed to GitHub.

For `infra-monitor`, this means moving away from manual deployment and making the update process more automatic.

Before CI/CD, the process is manual:

```text
Push code
↓
SSH into EC2
↓
Pull latest changes
↓
Rebuild Docker container
↓
Restart service
```

With CI/CD, the goal is:

```text
Push code to GitHub
↓
GitHub Actions runs checks
↓
Bash scripts are checked
↓
Docker image is built
↓
Docker Compose is validated
↓
EC2 redeploys the container
```

## Continuous Integration

Continuous Integration means checking the project automatically when code is pushed.

For `infra-monitor`, this can include:

* Checking Bash syntax
* Building the Docker image
* Validating the Docker Compose file

This helps catch problems before they reach the EC2 server.

Bakisly, GitHub gets to complain before the server does. Much better arrangement.

## Continuous Deployment

Continuous Deployment means deploying the project automatically after the checks pass.

For this project, GitHub Actions will connect to the EC2 instance over SSH and run a deployment script.

The deployment script should:

* Go into the project folder
* Pull the latest code from GitHub
* Rebuild the Docker container
* Restart the monitoring service
* Show the container status

## Why This Matters

Manual deployment works at the start, but it gets messy as the project grows.

Problems with manual deployment:

* Easy to forget a step
* Hard to repeat perfectly
* No automatic checks before deployment
* More chance of breaking something manually

CI/CD makes the project more reliable because the process becomes repeatable, tested, and automated.

## July Goal

By the end of July, the project should work like this:

```text
Terraform creates the EC2 infrastructure
↓
Docker packages the monitoring app
↓
GitHub Actions checks and deploys updates
↓
EC2 runs the latest container
```

This moves `infra-monitor` from a containerised monitoring script to a CI/CD-enabled cloud service.

That is a serious upgrade. Bruv the project is starting to move like a proper DevOps pipeline now.
