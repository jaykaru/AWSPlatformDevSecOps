module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.env
  vpc_cidr     = var.vpc_cidr
  tags         = var.tags
}
