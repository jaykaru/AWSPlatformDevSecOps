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
- ⏳ *Internet Gateway, Route Tables, and NAT Gateway are intentionally postponed to later stages.*

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
| Tier | Subnet / Resource | CIDR Block | AZ (Dynamic) | Public IP on Launch | Name Tag |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **VPC** | VPC | `10.20.0.0/16` | Region-wide | — | `aws-platform-devsecops-dev-vpc` |
| **Public** | Public-A | `10.20.1.0/24` | `eu-north-1a` (idx 0) | `true` | `aws-platform-devsecops-dev-public-a` |
| **Public** | Public-B | `10.20.2.0/24` | `eu-north-1b` (idx 1) | `true` | `aws-platform-devsecops-dev-public-b` |
| **Application** | Application-A | `10.20.11.0/24` | `eu-north-1a` (idx 0) | `false` | `aws-data-platform-dev-application-a` |
| **Application** | Application-B | `10.20.12.0/24` | `eu-north-1b` (idx 1) | `false` | `aws-data-platform-dev-application-b` |
| **Data** | Data-A | `10.20.21.0/24` | `eu-north-1a` (idx 0) | `false` | `aws-data-platform-dev-data-a` |
| **Data** | Data-B | `10.20.22.0/24` | `eu-north-1b` (idx 1) | `false` | `aws-data-platform-dev-data-b` |

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
*Expected plan output: `Plan: 7 to add, 0 to change, 0 to destroy` (1 VPC + 2 Public subnets + 2 Application subnets + 2 Data subnets).*

### Step 5: Deploy the Network (Optional)
When you are ready to provision the VPC and subnets in your AWS account:
```bash
terraform apply
```

### Step 6: Clean Up (Destroy)
To delete the created VPC and subnets to avoid unnecessary state:
```bash
terraform destroy
```

---

## 5. Next Steps / Roadmap

Now that the VPC and 3-tier subnets (Public, Application, Data) exist:
1. **Internet Gateway (IGW):** Attach an IGW to enable internet traffic into/out of the VPC.
2. **Route Tables:**
   - Create a **Public Route Table** (`0.0.0.0/0` -> IGW) and associate `public-a`, `public-b`.
   - Create **Private Route Tables** for application and data tiers.
3. **NAT Gateway:** Allow instances in application subnets to reach the internet safely for updates without accepting inbound traffic.
4. **Data Tier Isolation:** Ensure data subnets remain completely isolated (no direct internet or NAT routes).
5. **Security Groups & Network ACLs:** Add tier-specific firewall rules for end-to-end security (Web -> App -> Data).
