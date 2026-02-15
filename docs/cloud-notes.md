# PART 1

The cloud is:

*Someone else’s computer in a data centre that you rent over the internet.*


Instead of:

Buying a physical server
Plugging it into your house
Maintaining power, cooling, networking
You rent compute from a company like Amazon Web Services.


They handle:
Hardware
Networking
Physical security
Power redundancy


You handle:
Your OS
Your software
Your security configuration
This separation is important.


# PART 2

### Amazon EC2 = Elastic Compute Cloud.

In simple terms:

EC2 is a virtual machine (VM) you rent by the hour.

It’s just:

CPU

RAM

Storage

Network access

Running in a data centre.


When you launch an EC2 instance:

You choose an OS (Ubuntu, Amazon Linux, etc.)
You choose size (how powerful it is)
AWS boots it for you
You SSH into it

It behaves like a normal Linux machine




# PART 3

Regions & Availability Zones

AWS doesn’t have one giant building.
It has regions.

Example region:

eu-west-2

Inside each region are multiple:

Availability Zones (AZs)

Think:

Region = City
AZ = Separate data centres inside that city

Why this matters:

High availability
Fault tolerance
Reduced latency

Probably won’t use multiple AZs yet but just tryna understand why they exist.


# PART 4

Mental Model (Very Important)

When you launch EC2 in March, what’s actually happening?

You are:

Renting compute

In a specific region

In a specific availability zone

With a public IP

Secured by a firewall (security group)

Everything else is layers on top of this.
