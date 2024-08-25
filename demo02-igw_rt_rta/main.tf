module "vpc" {
  source = "./modules/t-aws-vpc"
}

module "public_subnet" {
  source = "./modules/t-aws-public_subnet"
  vpc-id = module.vpc.vpc-id
}

module "private_subnet" {
  source = "./modules/t-aws-private_subnet"
  vpc-id = module.vpc.vpc-id
}

module "igw" {
  source = "./modules/t-aws-igw"
  vpc-id = module.vpc.vpc-id
}

module "route_table" {
  source = "./modules/t-aws-rt"
  vpc-id = module.vpc.vpc-id
  igw-id = module.igw.igw-id
}

module "rta-internet_to_public_subnet" {
  source = "./modules/t-aws-rta"
  public_subnet-id = module.public_subnet.public_subnet-id
  #public_subnet-id = { for id in module.public_subnet.public_subnet-id : id => id }
  public_subnet-length = module.public_subnet.public_subnet-length
  rt-id = module.route_table.rt-id
}
