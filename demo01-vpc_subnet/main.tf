module "vpc" {
  source = "./modules/t-aws-vpc"
}

module "subnet" {
  source = "./modules/t-aws-subnet"
  vpc-id = module.vpc.vpc-id
}
