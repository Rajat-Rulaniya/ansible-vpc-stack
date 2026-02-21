# AWS VPC Infrastructure with Ansible — Infrastructure as Code

Fully automated provisioning of a production-ready **AWS VPC** with public/private subnets across 3 Availability Zones, NAT Gateway, Internet Gateway, route tables, and a Bastion Host — all using **Ansible** as the IaC tool.

![Ansible](https://img.shields.io/badge/IaC-Ansible-EE0000?style=flat&logo=ansible&logoColor=white)
![AWS](https://img.shields.io/badge/Cloud-AWS-232F3E?style=flat&logo=amazonwebservices&logoColor=white)
![VPC](https://img.shields.io/badge/Networking-VPC-FF9900?style=flat)

---

## What Gets Provisioned

### VPC & Networking (`vpc-setup.yml`)

| Resource | Details |
|----------|---------|
| **VPC** | `Vprofile-VPC` — `172.13.0.0/16` (65,536 IPs) with DNS support & hostnames enabled |
| **Public Subnet 1** | `172.13.1.0/24` in `us-east-1a` — auto-assigns public IPs |
| **Public Subnet 2** | `172.13.2.0/24` in `us-east-1b` — auto-assigns public IPs |
| **Public Subnet 3** | `172.13.3.0/24` in `us-east-1c` — auto-assigns public IPs |
| **Private Subnet 1** | `172.13.4.0/24` in `us-east-1a` |
| **Private Subnet 2** | `172.13.5.0/24` in `us-east-1b` |
| **Private Subnet 3** | `172.13.6.0/24` in `us-east-1c` |
| **Internet Gateway** | Attached to VPC for public subnet internet access |
| **NAT Gateway** | Placed in Public Subnet 1 — allows private subnets to reach the internet |
| **Public Route Table** | Routes `0.0.0.0/0` → Internet Gateway, associated with all 3 public subnets |
| **Private Route Table** | Routes `0.0.0.0/0` → NAT Gateway, associated with all 3 private subnets |

All resource IDs (VPC, subnets, IGW, NAT GW, route tables) are automatically saved to `vars/id-vars.txt` for use by downstream playbooks.

### Bastion Host (`bastion-instance.yml`)

| Resource | Details |
|----------|---------|
| **EC2 Key Pair** | `bastion_key` — private key auto-saved to `./keys/bastion_key.pem` |
| **Security Group** | `bastion_sg` — allows SSH (port 22) only from your IP (read from `myIp.txt`) |
| **EC2 Instance** | `t2.micro` in Public Subnet 2, with public IP, tagged with project metadata |

The Bastion Host serves as the **single SSH entry point** into the private subnets — a standard security practice to avoid exposing backend instances directly to the internet.

---

## Project Structure

```
├── vpc-setup.yml              # Playbook: provisions the entire VPC stack
├── bastion-instance.yml       # Playbook: provisions Bastion Host + security group + key pair
├── sample.yml                 # Playbook: sample EC2 key pair creation (reference/test)
├── vars/
│   ├── vpc_setup.txt          # Variables: VPC name, CIDR ranges, region, AZs
│   └── bastion_setup.txt      # Variables: Bastion AMI, region, IP whitelist
├── vars/id-vars.txt           # Auto-generated: all resource IDs from VPC setup (gitignored)
└── keys/                      # Auto-generated: SSH private keys (gitignored)
```

---

## How to Run

### Prerequisites

- **Ansible** installed with the `amazon.aws` collection
- **AWS credentials** configured (`~/.aws/credentials` or environment variables)
- **Python boto3** installed (`pip install boto3 botocore`)
- A file named `myIp.txt` in the project root containing your public IP in CIDR format (e.g., `203.0.113.25/32`)

### Step 1 — Provision the VPC

```bash
ansible-playbook vpc-setup.yml
```

This creates the full networking stack and saves all resource IDs to `vars/id-vars.txt`.

### Step 2 — Launch the Bastion Host

```bash
ansible-playbook bastion-instance.yml
```

This reads the VPC IDs from Step 1, creates a security group locked to your IP, and launches the Bastion EC2 instance.

### Step 3 — SSH into the Bastion

```bash
ssh -i keys/bastion_key.pem ubuntu@<bastion-public-ip>
```

From the Bastion, you can reach any instance in the private subnets.

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| **3 AZs** | High availability — subnets spread across `us-east-1a`, `1b`, `1c` |
| **Public + Private subnet separation** | Security best practice — backend services stay in private subnets, only the Bastion and load balancers go public |
| **NAT Gateway in Public Subnet** | Allows private instances to pull updates/packages without being directly exposed |
| **Bastion Host with IP-restricted SG** | SSH access only from a whitelisted IP — no open `0.0.0.0/0` on port 22 |
| **Resource IDs saved to file** | Enables playbook chaining — VPC setup outputs feed into Bastion setup automatically |
| **Idempotent design** | `exact_count: 1` and `if_exist_do_not_create: true` ensure re-runs don't create duplicates |

---

## Ansible Modules Used

| Module | Purpose |
|--------|---------|
| `amazon.aws.ec2_vpc_net` | Create VPC |
| `amazon.aws.ec2_vpc_subnet` | Create subnets |
| `amazon.aws.ec2_vpc_igw` | Create Internet Gateway |
| `amazon.aws.ec2_vpc_nat_gateway` | Create NAT Gateway |
| `amazon.aws.ec2_vpc_route_table` | Create and configure route tables |
| `amazon.aws.ec2_key` | Create EC2 key pairs |
| `amazon.aws.ec2_security_group` | Create security groups with rules |
| `amazon.aws.ec2_instance` | Launch EC2 instances |

---

## Tools & Technologies

| Category | Tool |
|----------|------|
| **IaC / Automation** | Ansible |
| **Cloud Provider** | AWS |
| **Networking** | VPC, Subnets, IGW, NAT GW, Route Tables |
| **Compute** | EC2 (Bastion Host) |
| **Security** | Security Groups, Key Pairs, Bastion pattern |

---
