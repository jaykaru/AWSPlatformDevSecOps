# AWS Platform DevSecOps - Terraform Infrastructure

This repository contains the Infrastructure as Code (IaC) setup for the **AWS Platform DevSecOps** project using Terraform.

The repository follows a step-by-step modular approach so that each AWS component can be learned, tested, and understood thoroughly before adding more complex infrastructure.

---

## 1. Project Overview & Current State

Currently, the project is focused on the foundational layer of any AWS architecture: **Amazon Virtual Private Cloud (VPC)**.

To keep things clear and easy to understand, we are intentionally starting **only with the VPC**:
- ✅ **Custom VPC** created in Region `eu-north-1` (Stockholm)
- ✅ Dedicated CIDR Block: `10.20.0.0/16` (providing 65,536 private IP addresses)
- ✅ DNS support and DNS hostnames enabled
- ⏳ *Subnets, Internet Gateway, Route Tables, and NAT Gateway are intentionally postponed to later stages.*

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

### VPC Specifications
| Parameter | Value | Purpose |
| :--- | :--- | :--- |
| **CIDR Block** | `10.20.0.0/16` | Private IP range for the cloud network |
| **enable_dns_support** | `true` | Allows AWS DNS resolver to resolve domain queries |
| **enable_dns_hostnames** | `true` | Assigns public/private DNS hostnames to instances |
| **Name Tag** | `aws-platform-devsecops-dev-vpc` | Easy resource identification in AWS Console |

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
*Expected plan output: `Plan: 1 to add, 0 to change, 0 to destroy` (only `aws_vpc`).*

### Step 5: Deploy the VPC (Optional)
When you are ready to provision the VPC in your AWS account:
```bash
terraform apply
```

### Step 6: Clean Up (Destroy)
To delete the created VPC and avoid any unnecessary state:
```bash
terraform destroy
```

---

## 5. Next Steps / Roadmap

Once you are comfortable with how the VPC works:
1. **Subnets:** Add Public and Private Subnets across multiple Availability Zones (`eu-north-1a`, `eu-north-1b`).
2. **Internet Gateway (IGW):** Enable public internet access for resources in public subnets.
3. **Route Tables:** Create and associate public and private route tables.
4. **NAT Gateway:** Allow instances in private subnets to reach the internet safely for updates without accepting inbound traffic.
5. **Security Groups & Network ACLs:** Add firewall rules for security.
