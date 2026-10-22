locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
    },
    var.tags
  )

  public_subnets = {
    public-a = {
      cidr_block = var.public_subnet_a_cidr
      az_index   = 0
    }

    public-b = {
      cidr_block = var.public_subnet_b_cidr
      az_index   = 1
    }
  }

  application_subnets = {
    application-a = {
      cidr_block = var.application_subnet_a_cidr
      az_index   = 0
    }

    application-b = {
      cidr_block = var.application_subnet_b_cidr
      az_index   = 1
    }
  }

  data_subnets = {
    data-a = {
      cidr_block = var.data_subnet_a_cidr
      az_index   = 0
    }

    data-b = {
      cidr_block = var.data_subnet_b_cidr
      az_index   = 1
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-vpc" }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    { Name = "aws-data-platform-${var.environment}-igw" }
  )
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-nat-eip" }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["public-a"].id

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-nat-gateway" }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    { Name = "aws-data-platform-${var.environment}-public-rt" }
  )
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table" "application" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    { Name = "aws-data-platform-${var.environment}-application-rt" }
  )
}

resource "aws_route" "application_nat_access" {
  route_table_id         = aws_route_table.application.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = data.aws_availability_zones.available.names[each.value.az_index]
  map_public_ip_on_launch = true

  lifecycle {
    precondition {
      condition     = each.value.az_index < length(data.aws_availability_zones.available.names)
      error_message = "Subnet az_index is out of range for available availability zones."
    }
  }

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-${each.key}" }
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "application" {
  for_each = local.application_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = data.aws_availability_zones.available.names[each.value.az_index]
  map_public_ip_on_launch = false

  lifecycle {
    precondition {
      condition     = each.value.az_index < length(data.aws_availability_zones.available.names)
      error_message = "Subnet az_index is out of range for available availability zones."
    }
  }

  tags = merge(
    local.common_tags,
    { Name = "aws-data-platform-${var.environment}-${each.key}" }
  )
}

resource "aws_route_table_association" "application" {
  for_each = aws_subnet.application

  subnet_id      = each.value.id
  route_table_id = aws_route_table.application.id
}

resource "aws_subnet" "data" {
  for_each = local.data_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = data.aws_availability_zones.available.names[each.value.az_index]
  map_public_ip_on_launch = false

  lifecycle {
    precondition {
      condition     = each.value.az_index < length(data.aws_availability_zones.available.names)
      error_message = "Subnet az_index is out of range for available availability zones."
    }
  }

  tags = merge(
    local.common_tags,
    { Name = "aws-data-platform-${var.environment}-${each.key}" }
  )
}
