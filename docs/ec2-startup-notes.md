# EC2 Startup Notes

## What I’m Actually Doing When I Launch EC2

When I launch an EC2 instance, I am:

- Renting a Linux computer inside an AWS data centre  
- Not a website  
- Not “cloud magic”  
- A real machine, just virtualised  

AWS owns the hardware.  
I control what runs on it.  

This is **Infrastructure as a Service (IaaS)**.

---

## The Decisions I Make When Launching

Every click during launch actually matters.

When launching EC2, I choose:

- **AMI** (the OS template)  
- **Instance type** (how powerful it is)  
- **Key pair** (how I prove it’s me)  
- **Networking + Security** (who is allowed in)  
- **Storage size**  

Each one affects how the machine behaves

---

## AMI — The Operating System Blueprint

**AMI = Amazon Machine Image**

This is a prebuilt OS template.

Example:
- Ubuntu Server (LTS)

This tells AWS:

> Boot a machine that already has Ubuntu installed and configured.

I am **NOT** manually installing Linux.  
AWS boots it instantly from a snapshot image.

### Key Difference

- **AMI** = what OS the machine runs  
- **Instance Type** = how powerful the machine is  

Do not confuse these.

---

## Instance Type — The Machine’s Power

Example:
- `t2.micro` (or `t3.micro`)

### Specs:
- 1 vCPU  
- 1 GB RAM  

### Enough for:
- Learning  
- Running scripts  
- Small services  
- Monitoring tools  

Think of instance type as choosing laptop specs in the cloud.

- Light work → small instance  
- Heavy production → larger instance  

Rn i dont need extra just need enough to understand

---

## Key Pair — How SSH Authentication Works

This is critical.

Instead of a password, I created:

- `infra-monitor-***.pem`

This is a **private key**.

### SSH Command

```bash
ssh -i infra-monitor-***.pem ubuntu@<public-ip>
```
## SSH Authentication — What Happens

### What happens:

- My computer → proves ownership using cryptography  
- AWS → verifies against stored public key  
- No password is sent  

---

### Why this is safer:

- Cannot be brute-forced easily  
- Not guessable  
- Much harder to attack  
- Industry standard for servers  

---

### Important Permission Step

```bash
chmod 400 infra-monitor-***.pem
```
If permissions are too open, SSH will refuse to use the key.

Reason:
If other users can read the key, it’s insecure gulp

## Security Groups — The Firewall

A **security group** is a virtual firewall attached to the instance.

### Example Rule

- **Port:** 22 (SSH)  
- **Source:** My IP  

**Meaning:**
> Only my current IP can attempt SSH access. we'll be alrite

---

### Risky Setting

- `0.0.0.0/0`

**Meaning:**
> Anyone in the world can try to connect.

They won’t automatically get in —  
but it **massively increases attack surface**.

---

### Best Practice

> Limit exposure as much as possible.

---

## What Happens When I Click "Launch"

Behind the scenes, AWS:

1. Selects hardware in my chosen region  
2. Creates a virtual machine  
3. Attaches storage (EBS volume)  
4. Boots the OS from the AMI  
5. Applies firewall rules  
6. Attaches my public SSH key  
7. Assigns a public IP address  

At that point:

> I officially own a remote Linux server

This is the foundation

---

## Regions & Availability Zones (AZs)

### Example Region

- `eu-west-2`

---

### Definitions

- **Region** → Geographic area  
- **Availability Zone (AZ)** → Separate physical data centre within that region  

---

### Current Setup

- One instance in one AZ  

### Future Setup

- Multiple AZs for resilience  

---

## how to think going forward

Rn I have:

- One Linux server  
- Accessible via SSH  
- Secured by a firewall  
- Running in a chosen region  

This is **raw infrastructure**.

---

### Future Layers

- **Docker** → run containers  
- **Ansible** → automate configuration  
- **CI/CD** → automate deployment  
- **Kubernetes** → manage multiple servers  

But everything starts with:

> Understanding one server properly

---

## Security Groups

### What is a Security Group?
A security group is a virtual firewall attached to an EC2 instance.  
It controls what traffic can enter (inbound) and leave (outbound) the server.

### What Does "Stateful" Mean?
Security groups are **stateful**.  
If inbound traffic is allowed, the response is automatically allowed back out.  
I don’t need separate rules for return traffic.

### Inbound vs Outbound
- **Inbound** → Who can connect to my server and on which port.  
- **Outbound** → What my server is allowed to connect to.

### Why `0.0.0.0/0` is Dangerous for SSH
`0.0.0.0/0` means anyone in the world can attempt to connect.  
For SSH (port 22), this exposes the server to constant scans and attacks

### Why Limiting to My IP is Better
Allowing SSH only from **my IP** stops attack surface and follows least privilege

---

## Key Concepts to Remember

- **AMI** → OS template  
- **Instance Type** → CPU/RAM power  
- **Key Pair** → cryptographic login  
- **Security Group** → firewall  
- **Region** → geographic area  
- **Availability Zone** → physical data centre  
- **Public IP** → how I access the server  
