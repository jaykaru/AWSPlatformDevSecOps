output "project_name" {
  description = "Name of the project"
  value       = var.project_name
}

output "aws_region" {
  description = "AWS deployment region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "Created VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "Created VPC CIDR block"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_a_id" {
  description = "Created Public Subnet A ID"
  value       = module.networking.public_subnet_a_id
}

output "public_subnet_a_az" {
  description = "Availability Zone for Public Subnet A"
  value       = module.networking.public_subnet_a_az
}
