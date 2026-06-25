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


## Day 5 — Docker Build in GitHub Actions

Today I added a Docker build check to the GitHub Actions workflow.

The goal was to make GitHub build the `infra-monitor` Docker image automatically when code is pushed to `main`.

Build command used:

```bash
docker build -f docker/Dockerfile -t infra-monitor .
```

### Why This Matters

Before this, I was building the Docker image manually on my Ubuntu VM or EC2.

Now GitHub Actions checks if the image can build before deployment happens.

This can catch issues like:

```text
broken Dockerfile
missing files
wrong paths
script permission problems
```
Mad Stuff now

### Workflow Job

A new job was added for the Docker build.

The important part is:

```yaml
needs: bash-checks
```

This means the Docker build only runs if the Bash syntax checks pass first.

### Current CI Flow

```text 
Push to main
↓
Bash scripts checked
↓
Docker image built
↓
Workflow passes if both checks work
```

### Result

The project now has two proper CI checks:

```text 
Bash syntax check
Docker build check
```

This makes `infra-monitor` safer because GitHub now checks both the scripts and the Docker image before any future deployment step.




## Day 6 — Docker Compose Validation

Today I added Docker Compose validation to the GitHub Actions workflow.

The goal was to make GitHub check the Compose file before any future deployment happens.

Command used:

```bash
docker compose -f docker/docker-compose.yml config
```

### What This Does

`docker compose config` checks the Compose file structure without actually starting the container.

It can catch things like:

```text
broken YAML
bad syntax
missing env files
wrong paths
the shabang
```

### CI Environment File

The Compose file uses:

```yaml
env_file:
  - day9.env
```

Since real env files should not be committed, the workflow creates a temporary one inside the GitHub runner.

Example:

```yaml
- name: Create CI environment file
  run: |
    cat > docker/day9.env <<'EOF'
    CPU_WARN_THRESHOLD=70
    MEMORY_WARN_THRESHOLD=70
    DISK_WARN_THRESHOLD=70
    INFRA_MONITOR_SYSTEM_LOG=/app/logs/day9-env-file.log
    INFRA_MONITOR_ERROR_LOG=/app/logs/day9-error.log
    EOF
```

This file only exists during the workflow run. It is NOT pushed to GitHub.

### Workflow Order

The Compose validation job uses:

```yaml
needs: docker-build
```

This means it only runs after the Docker image build passes.

Current CI flow:

```text
Push to main
↓
Bash scripts checked
↓
Docker image built
↓
Docker Compose validated
↓
Workflow passes
```

### Result

The project now has three CI quality gates:

```text
Bash syntax check
Docker build check
Docker Compose validation
```

This makes the pipeline safer because GitHub now checks the scripts, Dockerfile, and Compose setup before deployment gets added. boring but important day.


## Day 7 — GitHub Secrets

Today I added the GitHub Secrets needed for future EC2 deployment through GitHub Actions.

The goal was to keep sensitive deployment values out of the repo.

Secrets added:

```text
EC2_HOST
EC2_USER
EC2_SSH_KEY
```

What they are for:

```text
EC2_HOST    → Elastic IP attached to the EC2 instance
EC2_USER    → SSH user, usually ec2-user
EC2_SSH_KEY → private SSH key for deployment
```

`EC2_HOST` stores the Elastic IP address associated with the EC2 instance.

An Elastic IP is used instead of the default EC2 public IP because default public IPv4 addresses can change when an instance is stopped and started.

Using an Elastic IP keeps the GitHub secret stable and stops the deployment workflow from pointing at an old EC2 address.

Before adding the secrets, I tested SSH from my Ubuntu VM:

```bash
ssh -i ssh/infra-monitor-key.pem ec2-user@EC2_ELASTIC_IP "hostname && whoami && pwd"
```

This confirmed the host, user, and key were correct.

### Security Notes

Secrets should never be committed to GitHub.

Things like private keys, AWS keys, API tokens, and real `.env` files need to stay protected.

The EC2 instance uses an Elastic IP so the host value stays stable across stop/start cycles.

Manual SSH access is still restricted through the Security Group using a `/32` CIDR rule for my current public IP.

For future deployment from GitHub Actions, the Security Group access method may need to be adjusted because GitHub-hosted runners do not connect from my home IP.

The workflow will later use secrets like this:

```yaml
${{ secrets.EC2_HOST }}
${{ secrets.EC2_USER }}
${{ secrets.EC2_SSH_KEY }}
```

### Result

The repo is now prepared for GitHub Actions to connect to EC2 securely.

No secret values were committed, and the host value now uses the Elastic IP, so the future deployment setup should be more stable.

A day full of Debugging.

### Hollup, first we do Day 8 Security Group Considerations

The EC2 Security Group currently allows SSH only from my home public IP using a `/32` CIDR rule.

This is good for manual SSH from my Ubuntu VM, but GitHub Actions runners do not run from my home network.

For the GitHub Actions SSH test, the workflow will need to temporarily allow the current GitHub runner public IP on port 22, run the SSH command, and then remove that temporary rule afterwards.

Planned Day 8 flow:

```text
GitHub Actions runner starts
↓
Runner public IP is detected
↓
Temporary SSH rule is added to the EC2 Security Group
↓
GitHub Actions SSHs into EC2
↓
Temporary SSH rule is removed
```

This avoids permanently opening SSH to 0.0.0.0/0. aye that would be bad cuz

Long term, AWS SSM Session Manager or GitHub *OIDC* would be a cleaner approach because they can reduce reliance on inbound SSH rules and long-lived credentials.



## Day 8 — First SSH From GitHub Actions

Today I tested SSH from GitHub Actions into my EC2 instance.

The goal was simple, i had to prove that GitHub Actions can reach the server and run basic Linux commands remotely.

Commands tested on EC2:

```bash
hostname
whoami
pwd
```

### Security Group Issue

My EC2 Security Group only allows SSH from my home public IP using a `/32` rule.

That works from my Ubuntu VM, but GitHub-hosted runners do not use my home IP.

To handle this without opening SSH to the whole internet, the workflow temporarily allows the GitHub runner’s current public IP on port `22`.

Flow:

```text
GitHub Actions runner starts
↓
Runner public IP is detected
↓
Temporary SSH rule is added
↓
GitHub Actions connects to EC2
↓
Remote commands run
↓
Temporary SSH rule is removed
```

### Secrets Used

```text
EC2_HOST
EC2_USER
EC2_SSH_KEY
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
EC2_SECURITY_GROUP_ID
```

`EC2_HOST` uses the Elastic IP attached to the EC2 instance, so the SSH host stays stable even after stop/start cycles.

### Result

GitHub Actions can now SSH into the EC2 instance and run commands.

Current July flow:

```text
Push to main
↓
Bash checks
↓
Docker build
↓
Compose validation
↓
SSH into EC2
↓
Remote commands run successfully
```

This was a big CI/CD step, because the pipeline can now actually communicate with the cloud server instead of just running checks on GitHub.
