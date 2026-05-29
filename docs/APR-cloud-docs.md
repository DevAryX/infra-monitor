## April Week 1 — Networking and Security

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


## Summary

This week made cloud networking feel more real.
I now understand how the connection moves from my Ubuntu VM, through the internet, into AWS, through the Security Group, and finally into the EC2 instance.
The main improvement was locking down SSH so the server is still usable, but not randomly open to the whole internet.
