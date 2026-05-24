## April Day 1 — Public vs Private IPs

### My Current Setup

My local environment uses:
- Windows 11 as the host machine
- Ubuntu 22.04 LTS running inside Oracle VM VirtualBox
- VirtualBox network mode: NAT
- AWS EC2 instance running Amazon Linux 2023

The Ubuntu VM is used to SSH into the EC2 instance and manage the infra-monitor project.

### Public IP

A public IP is reachable from the internet.
In this project, the EC2 public IP is used to connect to the server using SSH.

Example connection flow:

```
Ubuntu VM → Internet → EC2 Public IP → AWS Security Group → EC2 Instance
```

## April Day 2 — VPC, Subnet and Internet Gateway

### AWS Network Structure

My EC2 instance sits inside an AWS network, not just randomly on the internet.

The basic structure is:

```text
AWS VPC → Public Subnet → EC2 Instance
```

### VPC

A VPC is like my own private network inside AWS.

It gives the EC2 instance a controlled place to run instead of being directly exposed with no structure.

### Public Subnet

My EC2 instance is inside a public subnet.

I know this because it has a public IPv4 address and I can SSH into it from my Ubuntu VM.

### Internet Gateway

The Internet Gateway is what lets the VPC connect to the internet.

Without it, my EC2 instance would not be reachable from my own machine.

### Route Table

The route table decides where network traffic goes.

For internet access, the important route is:

```text
0.0.0.0/0 → Internet Gateway
```

This basically means traffic going out to the internet gets sent through the Internet Gateway.

### Architecture Flow

```text
Windows 11 PC
↓
Ubuntu VM - VirtualBox NAT
↓
Home Router / Public IP
↓
Internet
↓
AWS Internet Gateway
↓
AWS VPC
↓
Public Subnet
↓
EC2 Instance - Amazon Linux 2023
```

### Why This Matters

This helped me understand that connecting to EC2 depends on more than just the public IP.

Several parts need to work together:

- Public IP
- Security Group
- Public Subnet
- Route Table
- Internet Gateway

So if SSH breaks, I now know there are multiple network layers to check instead of just assuming the server is broken.


## April Day 3 — Security Groups

A Security Group is like a firewall for my EC2 instance.

It controls what traffic can enter and leave the server.

### SSH Access

My EC2 instance allows SSH on port `22` only from my public IP.

```text
SSH → Port 22 → My Public IP /32
```

Using `/32` means only my exact IP can connect.

This is safer than:

```text
0.0.0.0/0
```

because that would allow anyone on the internet to try SSH.

### Outbound Access

The instance can access the internet using:

```text
All traffic → 0.0.0.0/0
```

This allows updates, package installs, and S3 uploads.

### Connection Flow

```text
Ubuntu VM → Internet → EC2 Public IP → Security Group → EC2 Instance
```

To test SSH:

```bash
nc -vz EC2_PUBLIC_IP 22
```
