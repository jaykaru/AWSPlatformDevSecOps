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
