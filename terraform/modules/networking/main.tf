locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
    },
    var.tags
  )
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
