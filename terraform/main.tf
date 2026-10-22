module "networking" {
  source = "./modules/networking"

  project_name              = var.project_name
  environment               = var.env
  vpc_cidr                  = var.vpc_cidr
  public_subnet_a_cidr      = var.public_subnet_a_cidr
  public_subnet_b_cidr      = var.public_subnet_b_cidr
  application_subnet_a_cidr = var.application_subnet_a_cidr
  application_subnet_b_cidr = var.application_subnet_b_cidr
  data_subnet_a_cidr        = var.data_subnet_a_cidr
  data_subnet_b_cidr        = var.data_subnet_b_cidr
  tags                      = var.tags
}
