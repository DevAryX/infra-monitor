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


## Day 3 — YAML Workflow Structure

Today I improved the first GitHub Actions workflow and focused on how the YAML structure actually works.

The workflow file is:

```text
.github/workflows/test.yml
```

The workflow now:

* Runs when code is pushed to `main`
* Can be started manually with `workflow_dispatch`
* Uses an Ubuntu GitHub runner
* Checks out the repo
* Runs a few basic test commands

Main structure:

```text
Workflow
↓
Trigger
↓
Job
↓
Runner
↓
Steps
↓
Commands or actions
```

Key parts learned:

```text
name    → workflow name
on      → trigger
jobs    → work to run
runs-on → runner machine
steps   → actions or commands
uses    → prebuilt GitHub Action
run     → shell command
```

The important new step was:

```yaml
uses: actions/checkout@v7
```

I accidentally set it to *checkout@v4* first, then changed it to *checkout@v7*.

This downloads the repo onto the GitHub runner so the workflow can actually access the project files.

Commands tested inside the workflow:

```yaml
- run: pwd
- run: ls -la
- run: echo "GitHub Actions is working"
```

### Result

The workflow now checks out the repo, lists the project files, and confirms GitHub Actions is running properly.

Current flow:

```text
Push to main
↓
GitHub Actions starts
↓
Repo is checked out
↓
Basic commands run
↓
Result appears in Actions tab
```

It is still simple, but this proves the repo can now be accessed inside the GitHub Actions runner. That is the base for later checks like Bash syntax, Docker builds, and EC2 deployment and all that.


## Day 4 — Bash Syntax Checks

Today I added Bash syntax checks to the GitHub Actions workflow.

This means GitHub now checks the main scripts before anything gets deployed.

Scripts checked:

```text
scripts/system_report.sh
scripts/resource_check.sh
```

Command used:

```bash
bash -n scripts/system_report.sh
bash -n scripts/resource_check.sh
```

### What `bash -n` Does

`bash -n` checks a Bash script for syntax errors without actually running it.

anyway

### Workflow Step

The workflow now checks out the repo, lists the scripts folder, and runs the Bash syntax checks.

```yaml
- name: Check Bash script syntax
  run: |
    bash -n scripts/system_report.sh
    bash -n scripts/resource_check.sh
```

### Why This Matters

Before this, a broken Bash script might only be noticed after deploying to EC2.

Now GitHub Actions catches it earlier.

Simple flow:

```text
Push to main
↓
GitHub Actions starts
↓
Bash scripts are checked
↓
Workflow fails if something is broken
```

### Result

This is the first proper quality gate in the CI/CD pipeline.

It is a small step, but it makes the project safer because broken Bash code gets caught before it reaches the server.

