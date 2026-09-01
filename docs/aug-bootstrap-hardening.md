# Post-August — EC2 Bootstrap Hardening

After finishing the August Monitoring & Security phase, I did a hardening pass to clean up issues found during real testing.

The main goal was simple:

```text
make deployment cleaner
make bootstrapping stronger
make the container observe the EC2 host properly
```

---

## Day 1 — Runtime and Deployment Hardening

### Runtime Bug Fix

The Dockerised Bash monitor tried to use:

```text
ip
```

but the Docker image did not have `iproute2` installed.

So the report showed:

```text
ip: command not found
```

The Docker image now installs `iproute2`, and CI checks that required runtime commands exist before deployment.

Small bug, but worth fixing properly.

### Host-Aware Monitoring

More testing showed the container was partly reporting container info instead of EC2 host info.

Examples:

```text
container hostname
container process namespace
Docker overlay filesystem
container network interfaces
```

That is not what I wanted.

The `infra-monitor` container is now treated as a host-observability workload.

It uses:

```text
host UTS namespace
host network namespace
host PID namespace
read-only host root mount
```

The Bash script now reads host OS and root filesystem info through the mounted host root.

So yeah, the report is now about the EC2 host, not just the container it runs inside.

### Container Restrictions

Even though the container needs more host visibility, it is still not privileged.

The container now uses:

```text
read-only container filesystem
dropped Linux capabilities
no-new-privileges
read-only host root mount
writable mounts only for logs, metrics and temp data
```

So it gets the visibility it needs without becoming an overpowered container for no reason.

### Deployment Checkout

The EC2 repo is now treated as a deployment checkout.

GitHub Actions updates it with:

```text
git fetch origin main
git reset --hard origin/main
```

Runtime files stay outside tracked Git state.

The deployment script no longer runs `git pull`.

Instead, it checks that the repo is clean and matches `origin/main`.

### Deployment Script Source

GitHub Actions now runs the repo version directly:

```text
scripts/deploy-infra-monitor.sh
```

The old duplicate script is no longer part of the deployment design:

```text
~/deploy-infra-monitor.sh
```

This is cleaner because there is now one real deploy script source.

### CI Protection

CI now checks that the Docker image contains required runtime commands, including:

```text
ip
```

It also checks that the Bash report is observing the host hostname and host root filesystem properly.

### Result

The existing EC2 can now receive cleaner deployments without relying on duplicated scripts or messy tracked runtime files.

The Infra Monitor report now describes the EC2 host properly instead of accidentally reporting container-only details.

Basically, this was a cleanup day, but a very important one.

The project is getting less “it works because I remember the setup” and more “it works because the setup is actually designed properly.”

---

## Day 2 — Terraform and Bootstrap Hardening

Day 2 focused on making fresh EC2 setup more predictable and less manual.

The goal was basically:

```
new EC2 instance
↓
bootstraps itself properly
↓
ready for deployment
```

### Bootstrap Structure

The old Terraform user-data setup was split into:

```
terraform/user_data.sh.tftpl
terraform/bootstrap.sh
```

User data now only handles the first-stage setup.

The main bootstrap logic lives in `bootstrap.sh`.

Terraform also calculates the SHA256 hash of `bootstrap.sh`, and the EC2 instance checks that hash before running it.

So the server does not just blindly run whatever script appears after cloning.

### Host Firewall

`firewalld` is now installed and enabled before Docker starts.

The public firewall zone allows SSH, but monitoring ports are not opened.

Docker still handles the rules it needs for its own internal networks.

A systemd dependency also makes sure Docker starts after `firewalld`.

### Docker Tooling

Docker Buildx and Docker Compose are no longer pulled from random `latest` releases.

The bootstrap now pins exact versions and checks downloaded files with SHA256 checksums.

Much cleaner. Less “hope latest did not change overnight” energy.

### Runtime Config

A fresh EC2 now creates:

```
docker/runtime.env
```

from the tracked example file.

Terraform inserts the configured S3 bucket and object key into that ignored runtime file.

Grafana admin credentials are generated on EC2 and stored outside the repo with mode `600`.

### EC2 Security

Terraform now explicitly configures:

```
IAM instance profile
IMDSv2-only metadata access
metadata hop limit 2
IPv6 metadata endpoint disabled
metadata tag access disabled
encrypted gp3 root EBS volume
```

### Replacement Strategy

Because the EC2 uses:

```
user_data_replace_on_change = true
```

these bootstrap changes intentionally replace the old EC2 instance.

The Elastic IP stays Terraform-managed and gets re-associated with the replacement instance.

So yeah, the actual server can be disposable, but the deployment address stays stable.

### Result

A fresh EC2 instance can now prepare itself much more reliably.

This makes the project less dependent on manual server setup and more like proper infrastructure that can be rebuilt cleanly.

---

### Fresh Infrastructure Verification

The existing EC2 instance was deliberately replaced through Terraform.

The EC2 instance ID changed, but the Terraform-managed Elastic IP stayed the same.

So the server changed, but the deployment address stayed stable.

The new instance needed no manual app setup.

Cloud-init automatically:

```
cloned the repo
verified the bootstrap script SHA256
installed required host packages
enabled firewalld
installed pinned Docker Buildx and Compose
checked downloaded plugin checksums
created docker/runtime.env
generated Grafana admin credentials
deployed the Docker Compose stack
verified the EC2 IAM role inside the app container
ran the full monitoring health check
```

### Reproducibility

Fresh Grafana recreated the Prometheus data source and full dashboard from Git.

The old Docker volumes were not needed to rebuild the monitoring config.

That is the key point.

The setup is not just surviving anymore, it can actually be rebuilt.

### Idempotency

I ran the rendered cloud-init user data a second time.

The bootstrap completed successfully again.

It did not generate a new Grafana password or dirty the Git deployment checkout.

So yeah, the bootstrap can safely converge instead of making a mess every time it runs.

### Reboot Recovery

I rebooted the replacement EC2 instance.

After reboot:

```
firewalld returned
Docker returned
Node Exporter returned
Prometheus returned
Grafana returned
monitoring health checks passed
```

### Final Result

The EC2 server is now treated as disposable infrastructure.

The application and monitoring setup are rebuilt from:

```
Terraform
+
GitHub
+
bootstrap code
+
external runtime configuration
```

instead of random manual server state.

This is the proper finish to the hardening pass.

The server can be replaced, the stack can come back, and the Elastic IP keeps deployment stable.

That is exactly what I wanted.

