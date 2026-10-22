output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs by subnet key"
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "public_subnet_azs" {
  description = "Public subnet availability zones by subnet key"
  value       = { for k, s in aws_subnet.public : k => s.availability_zone }
}

output "application_subnet_ids" {
  description = "Application subnet IDs by subnet key"
  value       = { for k, s in aws_subnet.application : k => s.id }
}

output "application_subnet_azs" {
  description = "Application subnet availability zones by subnet key"
  value       = { for k, s in aws_subnet.application : k => s.availability_zone }
}

output "data_subnet_ids" {
  description = "Data subnet IDs by subnet key"
  value       = { for k, s in aws_subnet.data : k => s.id }
}

output "data_subnet_azs" {
  description = "Data subnet availability zones by subnet key"
  value       = { for k, s in aws_subnet.data : k => s.availability_zone }
}
