output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "nat_eip_id" {
  description = "Elastic IP allocation ID for NAT Gateway"
  value       = aws_eip.nat.id
}

output "nat_eip_public_ip" {
  description = "Elastic IP public address for NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.this.id
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "application_route_table_id" {
  description = "Application route table ID"
  value       = aws_route_table.application.id
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
