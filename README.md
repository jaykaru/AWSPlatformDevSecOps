# AWS Platform DevSecOps - Terraform Infrastructure

This repository contains the Infrastructure as Code (IaC) setup for the **AWS Platform DevSecOps** project using Terraform.

The repository follows a step-by-step modular approach so that each AWS component can be learned, tested, and understood thoroughly before adding more complex infrastructure.

---

## 1. Project Overview & Current State

Currently, the project focuses on foundational 3-tier networking: **Amazon Virtual Private Cloud (VPC)** with **Public**, **Application**, and **Data** subnets across multiple Availability Zones.

To keep things modular and maintainable, all network tiers are managed via the reusable networking module (`modules/networking/`):
- ✅ **Custom VPC** created in Region `eu-north-1` (Stockholm)
- ✅ Dedicated CIDR Block: `10.20.0.0/16` (65,536 private IP addresses)
- ✅ DNS support and DNS hostnames enabled
- ✅ **Public Subnets (Web/Ingress tier):**
  - **Public-A:** `10.20.1.0/24` in `eu-north-1a` (AZ index `0`, `map_public_ip_on_launch = false`)
  - **Public-B:** `10.20.2.0/24` in `eu-north-1b` (AZ index `1`, `map_public_ip_on_launch = false`)
  *(Note: Auto-assigning public IPs is disabled for DevSecOps compliance; internet ingress will be managed via Application Load Balancers).*
- ✅ **Application Subnets (App/Compute tier):**
  - **Application-A:** `10.20.11.0/24` in `eu-north-1a` (AZ index `0`, `map_public_ip_on_launch = false`)
  - **Application-B:** `10.20.12.0/24` in `eu-north-1b` (AZ index `1`, `map_public_ip_on_launch = false`)
- ✅ **Data Subnets (Database/Storage tier):**
  - **Data-A:** `10.20.21.0/24` in `eu-north-1a` (AZ index `0`, `map_public_ip_on_launch = false`)
  - **Data-B:** `10.20.22.0/24` in `eu-north-1b` (AZ index `1`, `map_public_ip_on_launch = false`)
- ✅ AZ names dynamically discovered via `data "aws_availability_zones" "available"`
- ✅ Subnet safety check via `precondition` ensuring AZ index is within available AZ bounds
- ✅ **Internet Gateway (IGW):** Created (`aws-data-platform-dev-igw`) and attached to the VPC
- ✅ **Public Route Table:** Created (`aws-data-platform-dev-public-rt`) and associated with `public-a` and `public-b`
- ✅ **Default Internet Route:** Route `0.0.0.0/0` targeting the Internet Gateway attached to the Public Route Table
- ✅ **Elastic IP (EIP):** Allocated (`aws-platform-devsecops-dev-nat-eip`) specifically for the NAT Gateway
- ✅ **NAT Gateway:** Provisioned (`aws-platform-devsecops-dev-nat-gateway`) in `public-a` using the allocated EIP
- ✅ **Application Route Table:** Created (`aws-data-platform-dev-application-rt`) and associated with `application-a` and `application-b`
- ✅ **Application Outbound Internet Route:** Route `0.0.0.0/0` targeting the NAT Gateway for private outbound internet access
- ✅ **VPC Default Security Group:** Managed and tagged (`aws-platform-devsecops-dev-default-sg`)
- ✅ **CloudWatch Log Group:** Created (`/aws/vpc/aws-platform-devsecops/dev/flow-logs`) with 30-day retention
- ✅ **IAM Role & Policy for Flow Logs:** Role (`aws-platform-devsecops-dev-vpc-flow-logs-role`) with permissions to publish log streams and events to CloudWatch
- ✅ **VPC Flow Log:** Enabled (`ALL` traffic) to capture network telemetry and stream to CloudWatch Logs
- ⏳ *Data Tier Route Table (isolated) and Application Security Groups / NACLs are planned for next steps.*

---

## 2. VPC Flow Logs Architecture & Telemetry Data Flow

VPC Flow Logs capture IP traffic metadata traversing the network interfaces in your VPC, publishing this information directly to Amazon CloudWatch Logs for security monitoring, compliance auditing, and network troubleshooting.

### Telemetry Data Flow

```text
                      AWS VPC
                    10.20.0.0/16
                         │
                         │ network-flow metadata
                         ▼
                  VPC Flow Logs
                         │
                         │ assumes
                         ▼
                    IAM Role
                         │
                         │ permissions
                         ▼
                  CloudWatch Logs
                         │
                         ▼
               Troubleshooting /
                security analysis
```

### What Does a VPC Flow Log Record Tell Us?

A VPC Flow Log record does **not** capture raw packet payloads (i.e., message body or application data). Instead, it logs **network layer metadata** about connection attempts and network flows.

#### 1. Default Record Format
A standard flow log entry follows this structure:
```text
<version> <account-id> <interface-id> <srcaddr> <dstaddr> <srcport> <dstport> <protocol> <packets> <bytes> <start> <end> <action> <log-status>
```

Example record:
```text
2 123456789012 eni-0123456789abcdef0 10.20.1.15 198.51.100.2 443 51234 6 15 8400 1620000000 1620000060 ACCEPT OK
```

#### 2. Key Fields & What They Reveal

| Field | Meaning | Operational & DevSecOps Value |
| :--- | :--- | :--- |
| **`srcaddr` & `dstaddr`** | Source and destination IP addresses | Identifies *who* initiated the traffic and *who* received it. Crucial for detecting unexpected external IP communication or internal lateral movement. |
| **`srcport` & `dstport`** | Source and destination ports | Indicates which service is being accessed (e.g., port `443` HTTPS, `80` HTTP, `22` SSH, `5432` PostgreSQL, `3306` MySQL). |
| **`protocol`** | IANA protocol number | Identifies transport layer protocol: `6` for TCP, `17` for UDP, `1` for ICMP. |
| **`packets` & `bytes`** | Packet count and total volume transferred | Quantifies traffic size during the capture window. Essential for monitoring bandwidth usage and detecting data exfiltration spikes. |
| **`action`** | **`ACCEPT`** or **`REJECT`** | **`ACCEPT`:** Traffic was permitted by both Security Groups and NACLs.<br>**`REJECT`:** Traffic was blocked by either a Security Group rule or a NACL rule. |
| **`start` & `end`** | Epoch timestamps for the capture window | Pinpoints the exact time window when the network activity took place. |
| **`interface-id`** | ENI ID (`eni-xxxxxx`) | Directly ties network traffic to a specific AWS resource (EC2 instance, ALB, NAT Gateway, RDS instance). |
| **`log-status`** | Logging status (`OK`, `NODATA`, `SKIPDATA`) | Indicates whether the record was captured normally or if data was skipped. |

#### 3. How Flow Logs Are Used in Practice
- **Security & Incident Analysis:** Sudden spikes in `REJECT` actions on sensitive ports (e.g., `22` SSH or `3389` RDP) help detect port scanning or brute-force connection attempts.
- **Troubleshooting Connectivity:** If an application instance cannot reach a backend database or an external API, checking for `REJECT` records quickly confirms whether a Security Group or NACL is improperly blocking the request.
- **Compliance & Network Audits:** Provides an immutable audit trail showing all communications entering, leaving, and moving laterally within the VPC.

---

## 3. Directory Structure

All Terraform configurations live in the `terraform/` directory:

```text
AwsPlatformDevSecOps/
├── .gitignore
├── README.md
└── terraform/
    ├── main.tf              # Root module caller invoking child modules
    ├── providers.tf         # AWS Provider configuration (region, profile)
    ├── versions.tf          # Terraform & AWS provider version constraints
    ├── variables.tf         # Root input variable definitions
    ├── terraform.tfvars     # Environment-specific input values
    ├── outputs.tf           # Root outputs exposed after deployment
    └── modules/
        └── networking/      # Reusable networking module
            ├── main.tf      # aws_vpc resource definition
            ├── variables.tf # Module input variables
            └── outputs.tf   # Module outputs (vpc_id, vpc_cidr_block)
```

---

## 4. Configuration Details

### AWS Provider & Environment
- **AWS Region:** `eu-north-1`
- **AWS Profile:** `terraform-lab-jk`
- **Environment:** `dev`
- **Project Name:** `aws-platform-devsecops`

### VPC & Subnet Specifications
| Tier / Component | Resource | CIDR Block / Details | AZ (Dynamic) | Public IP on Launch | Name Tag |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **VPC** | VPC | `10.20.0.0/16` | Region-wide | — | `aws-platform-devsecops-dev-vpc` |
| **Default Security Group** | SG | Restricted baseline default SG | Region-wide | — | `aws-platform-devsecops-dev-default-sg` |
| **CloudWatch Log Group** | Log Group | `/aws/vpc/aws-platform-devsecops/dev/flow-logs` (30d retention) | Region-wide | — | `aws-platform-devsecops-dev-vpc-flow-logs` |
| **IAM Role** | IAM Role | Trust policy for `vpc-flow-logs.amazonaws.com` | Global | — | `aws-platform-devsecops-dev-vpc-flow-logs-role` |
| **IAM Policy** | IAM Role Policy | CloudWatch log streaming permissions | Global | — | `aws-platform-devsecops-dev-vpc-flow-logs-policy` |
| **VPC Flow Log** | Flow Log | Traffic type: `ALL`, destination: CloudWatch | Region-wide | — | `aws-platform-devsecops-dev-vpc-flow-log` |
| **Internet Gateway** | IGW | Attached to VPC | Region-wide | — | `aws-data-platform-dev-igw` |
| **Elastic IP** | EIP (NAT) | `domain = "vpc"` | Region-wide | — | `aws-platform-devsecops-dev-nat-eip` |
| **NAT Gateway** | NAT Gateway | Located in `public-a` | `eu-north-1a` | — | `aws-platform-devsecops-dev-nat-gateway` |
| **Public Routing** | Public Route Table | `0.0.0.0/0` -> IGW | Region-wide | — | `aws-data-platform-dev-public-rt` |
| **Application Routing** | App Route Table | `0.0.0.0/0` -> NAT Gateway | Region-wide | — | `aws-data-platform-dev-application-rt` |
| **Public Subnets** | Public-A | `10.20.1.0/24` | `eu-north-1a` (idx 0) | `false` | `aws-platform-devsecops-dev-public-a` |
| **Public Subnets** | Public-B | `10.20.2.0/24` | `eu-north-1b` (idx 1) | `false` | `aws-platform-devsecops-dev-public-b` |
| **Application Subnets** | Application-A | `10.20.11.0/24` | `eu-north-1a` (idx 0) | `false` | `aws-data-platform-dev-application-a` |
| **Application Subnets** | Application-B | `10.20.12.0/24` | `eu-north-1b` (idx 1) | `false` | `aws-data-platform-dev-application-b` |
| **Data Subnets** | Data-A | `10.20.21.0/24` | `eu-north-1a` (idx 0) | `false` | `aws-data-platform-dev-data-a` |
| **Data Subnets** | Data-B | `10.20.22.0/24` | `eu-north-1b` (idx 1) | `false` | `aws-data-platform-dev-data-b` |

---

## 5. How to Run

> **Important:** Always execute Terraform commands inside the `terraform/` folder (or use `terraform -chdir=terraform ...`), as that is where the root configuration files reside.

### Step 1: Navigate to the Terraform Directory
```bash
cd terraform
```

### Step 2: Initialize Terraform
Downloads the required AWS provider plugin (`hashicorp/aws ~> 5.0`) and registers child modules:
```bash
terraform init
```

### Step 3: Validate the Code
Checks the syntax and configuration for correctness:
```bash
terraform validate
```

### Step 4: Preview the Changes
See what Terraform plans to create without applying any changes:
```bash
terraform plan
```
*Expected plan output: `Plan: 23 to add, 0 to change, 0 to destroy`*
- 1 VPC (`aws_vpc.this`)
- 1 Default Security Group (`aws_default_security_group.this`)
- 1 CloudWatch Log Group (`aws_cloudwatch_log_group.vpc_flow_logs`)
- 1 IAM Role (`aws_iam_role.vpc_flow_logs`)
- 1 IAM Role Policy (`aws_iam_role_policy.vpc_flow_logs`)
- 1 VPC Flow Log (`aws_flow_log.vpc`)
- 1 Internet Gateway (`aws_internet_gateway.this`)
- 1 Elastic IP (`aws_eip.nat`)
- 1 NAT Gateway (`aws_nat_gateway.this`)
- 2 Route Tables: Public (`aws_route_table.public`) & Application (`aws_route_table.application`)
- 2 Routes: Internet default (`0.0.0.0/0` -> IGW) & App NAT default (`0.0.0.0/0` -> NAT)
- 4 Route Table Associations: 2 Public (`public-a`, `public-b`) + 2 Application (`application-a`, `application-b`)
- 6 Subnets across Public, Application, and Data tiers

### Step 5: Deploy the Network (Optional)
When you are ready to provision the VPC and networking resources in your AWS account:
```bash
terraform apply
```

### Step 6: Clean Up (Destroy)
To delete the created infrastructure and avoid any unwanted AWS costs:
```bash
terraform destroy
```

---

## 6. Next Steps / Roadmap

Now that the VPC, Internet Gateway, Public Routing, NAT Gateway, Application Routing, and 3-Tier Subnets exist:
1. **Data Tier Route Table:** Create a dedicated, isolated route table for `data-a` & `data-b` with **no** internet routes (`0.0.0.0/0`) for maximum database protection.
2. **Security Groups & Network ACLs:** Add firewall rules controlling traffic strictly between tiers (Internet -> Public -> App -> Data).
3. **Multi-AZ NAT Gateway (Optional / Prod readiness):** Deploy an additional NAT Gateway in `public-b` for high availability in production environments.
