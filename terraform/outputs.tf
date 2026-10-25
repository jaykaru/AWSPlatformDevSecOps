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

output "internet_gateway_id" {
  description = "Created Internet Gateway ID"
  value       = module.networking.internet_gateway_id
}

output "nat_eip_id" {
  description = "Created Elastic IP allocation ID for NAT Gateway"
  value       = module.networking.nat_eip_id
}

output "nat_eip_public_ip" {
  description = "Created Elastic IP public IP address for NAT Gateway"
  value       = module.networking.nat_eip_public_ip
}

output "nat_gateway_id" {
  description = "Created NAT Gateway ID"
  value       = module.networking.nat_gateway_id
}

output "public_route_table_id" {
  description = "Created public route table ID"
  value       = module.networking.public_route_table_id
}

output "application_route_table_id" {
  description = "Created application route table ID"
  value       = module.networking.application_route_table_id
}

output "public_subnet_ids" {
  description = "Created public subnet IDs by subnet key"
  value       = module.networking.public_subnet_ids
}

output "public_subnet_azs" {
  description = "Availability zones for public subnets by subnet key"
  value       = module.networking.public_subnet_azs
}

output "application_subnet_ids" {
  description = "Created application subnet IDs by subnet key"
  value       = module.networking.application_subnet_ids
}

output "application_subnet_azs" {
  description = "Availability zones for application subnets by subnet key"
  value       = module.networking.application_subnet_azs
}

output "data_subnet_ids" {
  description = "Created data subnet IDs by subnet key"
  value       = module.networking.data_subnet_ids
}

output "data_subnet_azs" {
  description = "Availability zones for data subnets by subnet key"
  value       = module.networking.data_subnet_azs
}
