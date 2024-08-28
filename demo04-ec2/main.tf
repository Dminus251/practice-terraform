module "vpc" { #VPC
  source = "./modules/t-aws-vpc"
}

module "public_subnet" { #Public Subnet
  source 	     = "./modules/t-aws-public_subnet"
  count 	     = 2 #하드 코딩 해도 되나...
  vpc-id	     = module.vpc.vpc-id
  public_subnet-cidr = var.public_subnet-cidr[count.index]
  public_subnet-az   = var.public_subnet-az[count.index]
  public_subnet-name = var.public_subnet-name[count.index]
}

module "private_subnet" { #Private Subnet
  source = "./modules/t-aws-private_subnet"
  count = 2
  vpc-id = module.vpc.vpc-id
  private_subnet-cidr = var.private_subnet-cidr[count.index]
  private_subnet-az = var.private_subnet-az[count.index]
  private_subnet-name = var.private_subnet-name[count.index]
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
  count = length(module.public_subnet) #이만큼 반복해서 모듈 생성
  subnet-id = module.public_subnet[count.index].public_subnet-id
  rt-id = module.route_table-igw_to_vpc.rt-id
}

module "eip" { #Elastic IP
  source = "./modules/t-aws-eip"
  count = length(module.private_subnet)
}

module "nat" { #NAT Gateway
  source = "./modules/t-aws-nat"
  count = length(module.private_subnet)
  eip-id = module.eip[count.index].eip-id
  subnet-id = module.public_subnet[count.index].public_subnet-id  #nat는 public subnet에 위치해야 함
}

module "route_table-internet_to_nat" { #Route Internet Traffic to NAT
  source = "./modules/t-aws-rt"
  count = length(module.private_subnet)
  vpc-id = module.vpc.vpc-id
  gateway-id = module.nat[count.index].nat-id
  rt-usage = "nat"
}

module "rta-internet_to_nat" { #Associate route_table-internet_to_nat with Private Subnet
  count = length(module.private_subnet)
  source = "./modules/t-aws-rta"
  subnet-id = module.private_subnet[count.index].private_subnet-id
  rt-id = module.route_table-internet_to_nat[count.index].rt-id
}

#module "ec2" {
#  #현재 인프라는 public subnet 2개, private subnet 2개임
#  #서브넷 확장 시 수정 필요
#  source = "./modules/t-aws-ec2"
#
#  count = length(module.public_subnet) + length(module.private_subnet)
#
#  ec2-subnet = count.index < 2 ? module.public_subnet[count.index] : module.private_subnet[4-count.index]
#
#  ec2-az =  count.index % 2 == 0 ? "ap-northeast-2a" : "ap-northeast-2c"
#
#  ec2-key_name = "0828"
#
#  ec2-usage = count.index < 2 ? "public-${count.index}" : "private-${count.index}"
#}



