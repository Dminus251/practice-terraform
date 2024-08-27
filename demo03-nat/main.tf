module "vpc" { #VPC
  source = "./modules/t-aws-vpc"
}

module "public_subnet" { #Public Subnet
  source = "./modules/t-aws-public_subnet"
  vpc-id = module.vpc.vpc-id
}

module "private_subnet" { #Private Subnet
  source = "./modules/t-aws-private_subnet"
  vpc-id = module.vpc.vpc-id
}

module "igw" { #Internet Gateway
  source = "./modules/t-aws-igw"
  vpc-id = module.vpc.vpc-id
}

module "route_table-igw_to_vpc" { #Route Internet Traffic To IGW
  source = "./modules/t-aws-rt"
  vpc-id = module.vpc.vpc-id
  gateway-id = module.igw.igw-id
  rt-usage = "igw"
}

module "rta-internet_to_public_subnet" { #Associate route_table-igw_to_vpc with Public Subnet
  source = "./modules/t-aws-rta"
  count = module.public_subnet.public_subnet-length #이만큼 반복해서 모듈 생성
  subnet-id = module.public_subnet.public_subnet-id[count.index]
  rt-id = module.route_table-igw_to_vpc.rt-id
}

module "eip" { #Elastic IP
  source = "./modules/t-aws-eip"
  count = module.private_subnet.private_subnet-length
}

module "nat" { #NAT Gateway
  source = "./modules/t-aws-nat"
  count = module.private_subnet.private_subnet-length
  eip-id = module.eip[count.index].eip-id
  subnet-id = module.public_subnet.public_subnet-id[count.index]  #nat는 public subnet에 위치해야 함
}

module "route_table-internet_to_nat" { #Route Internet Traffic to NAT
  source = "./modules/t-aws-rt"
  count = module.private_subnet.private_subnet-length
  vpc-id = module.vpc.vpc-id
  gateway-id = module.nat[count.index].nat-id
  rt-usage = "nat"
}

module "rta-internet_to_nat" { #Associate route_table-internet_to_nat with Private Subnet
  source = "./modules/t-aws-rta"
  count = module.private_subnet.private_subnet-length #이만큼 반복해서 생성
  subnet-id = module.private_subnet.private_subnet-id[count.index]
  rt-id = module.route_table-internet_to_nat[count.index].rt-id
}
