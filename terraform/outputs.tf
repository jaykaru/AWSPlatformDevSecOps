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
