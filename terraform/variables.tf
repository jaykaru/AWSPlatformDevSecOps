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

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
