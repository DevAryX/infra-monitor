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

This moves `infra-monitor` from a containerised monitoring script to a CI/CD-enabled cloud service.

That is a serious upgrade. Bruv the project is starting to move like a proper DevOps pipeline now.

---

## Day 2 — First GitHub Actions Workflow

Today I created the first GitHub Actions workflow for `infra-monitor`.

The workflow file was created at:

```text
.github/workflows/test.yml
```

The goal was simple: prove that GitHub Actions can run automation when I push code to `main`.

The workflow runs on:

```yaml
runs-on: ubuntu-latest
```

It triggers when code is pushed to `main`, and it can also be started manually using:

```yaml
workflow_dispatch:
```

The first test step was basic:

```bash
echo "GitHub Actions is working"
```

### What I Learned

A GitHub Actions workflow is just automation stored inside:

```text
.github/workflows/
```

Main parts:

```text
name  → workflow name
on    → what triggers it
jobs  → work to run
steps → commands/actions inside the job
run   → shell command
```

Simple flow:

```text
Push to GitHub
↓
GitHub Actions starts
↓
Ubuntu runner runs the job
↓
Result appears in the Actions tab
```

### Result

The first workflow ran successfully.

This is the foundation for the CI/CD pipeline. Right now it just proves Actions works, but later it will check Bash scripts, build Docker, validate Compose, and eventually deploy to EC2 automatically.

