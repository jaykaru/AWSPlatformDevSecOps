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
  - **Public-A:** `10.20.1.0/24` in `eu-north-1a` (AZ index `0`, `map_public_ip_on_launch = true`)
  - **Public-B:** `10.20.2.0/24` in `eu-north-1b` (AZ index `1`, `map_public_ip_on_launch = true`)
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
- ⏳ *Data Tier Route Table (isolated) and Security Groups / NACLs are postponed to next steps.*

---

## 2. Directory Structure

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

## 3. Configuration Details

### AWS Provider & Environment
- **AWS Region:** `eu-north-1`
- **AWS Profile:** `terraform-lab-jk`
- **Environment:** `dev`
- **Project Name:** `aws-platform-devsecops`

### VPC & Subnet Specifications
| Tier / Component | Resource | CIDR Block / Details | AZ (Dynamic) | Public IP on Launch | Name Tag |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **VPC** | VPC | `10.20.0.0/16` | Region-wide | — | `aws-platform-devsecops-dev-vpc` |
| **Internet Gateway** | IGW | Attached to VPC | Region-wide | — | `aws-data-platform-dev-igw` |
| **Elastic IP** | EIP (NAT) | `domain = "vpc"` | Region-wide | — | `aws-platform-devsecops-dev-nat-eip` |
| **NAT Gateway** | NAT Gateway | Located in `public-a` | `eu-north-1a` | — | `aws-platform-devsecops-dev-nat-gateway` |
| **Public Routing** | Public Route Table | `0.0.0.0/0` -> IGW | Region-wide | — | `aws-data-platform-dev-public-rt` |
| **Application Routing** | App Route Table | `0.0.0.0/0` -> NAT Gateway | Region-wide | — | `aws-data-platform-dev-application-rt` |
| **Public Subnets** | Public-A | `10.20.1.0/24` | `eu-north-1a` (idx 0) | `true` | `aws-platform-devsecops-dev-public-a` |
| **Public Subnets** | Public-B | `10.20.2.0/24` | `eu-north-1b` (idx 1) | `true` | `aws-platform-devsecops-dev-public-b` |
| **Application Subnets** | Application-A | `10.20.11.0/24` | `eu-north-1a` (idx 0) | `false` | `aws-data-platform-dev-application-a` |
| **Application Subnets** | Application-B | `10.20.12.0/24` | `eu-north-1b` (idx 1) | `false` | `aws-data-platform-dev-application-b` |
| **Data Subnets** | Data-A | `10.20.21.0/24` | `eu-north-1a` (idx 0) | `false` | `aws-data-platform-dev-data-a` |
| **Data Subnets** | Data-B | `10.20.22.0/24` | `eu-north-1b` (idx 1) | `false` | `aws-data-platform-dev-data-b` |

---

## 4. How to Run

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
*Expected plan output: `Plan: 16 to add, 0 to change, 0 to destroy`*
- 1 VPC (`aws_vpc`)
- 1 Internet Gateway (`aws_internet_gateway`)
- 1 Elastic IP (`aws_eip`)
- 1 NAT Gateway (`aws_nat_gateway`)
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

## 5. Next Steps / Roadmap

Now that the VPC, Internet Gateway, Public Routing, NAT Gateway, Application Routing, and 3-Tier Subnets exist:
1. **Data Tier Route Table:** Create a dedicated, isolated route table for `data-a` & `data-b` with **no** internet routes (`0.0.0.0/0`) for maximum database protection.
2. **Security Groups & Network ACLs:** Add firewall rules controlling traffic strictly between tiers (Internet -> Public -> App -> Data).
3. **Multi-AZ NAT Gateway (Optional / Prod readiness):** Deploy an additional NAT Gateway in `public-b` for high availability in production environments.
