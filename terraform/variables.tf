variable "env" {
  description = "Environment for resource deployment (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
}

variable "project_name" {
  description = "Project name used for tagging and naming"
  type        = string
  default     = "aws-platform-devsecops"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for Public Subnet A"
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for Public Subnet B"
  type        = string
}

variable "application_subnet_a_cidr" {
  description = "CIDR block for Application Subnet A"
  type        = string
}

variable "application_subnet_b_cidr" {
  description = "CIDR block for Application Subnet B"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
