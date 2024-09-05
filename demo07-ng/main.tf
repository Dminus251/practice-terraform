locals {
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}


############################ NETWORK Configuration ###########################

#VPC
module "vpc" { 
  source = "./modules/t-aws-vpc"
}

#Public Subnet
module "public_subnet" { 
  source 	     = "./modules/t-aws-public_subnet"
  count 	     = length(var.public_subnet-cidr)
  vpc-id	     = module.vpc.vpc-id
  public_subnet-cidr = var.public_subnet-cidr[count.index]
  public_subnet-az   = count.index % 2 == 0 ? var.public_subnet-az[0] : var.public_subnet-az[1]
  public_subnet-name = var.public_subnet-name[count.index]
}

#Private Subnet
module "private_subnet" { #Private Subnet
  source 	      = "./modules/t-aws-private_subnet"
  count 	      = length(var.private_subnet-cidr)
  vpc-id 	      = module.vpc.vpc-id
  private_subnet-cidr = var.private_subnet-cidr[count.index]
  private_subnet-az   = count.index % 2 == 0 ? var.private_subnet-az[0] : var.private_subnet-az[1]
  private_subnet-name = var.private_subnet-name[count.index]
}

#Internet Gateway
module "igw" { 
  source = "./modules/t-aws-igw"
  vpc-id = module.vpc.vpc-id
}

#Route Table: From 0.0.0.0/0 to IGW
module "route_table-igw_to_vpc" {
  source     = "./modules/t-aws-rt"
  vpc-id     = module.vpc.vpc-id
  gateway-id = module.igw.igw-id
  rt-usage   = "igw"
}

#Associate Route Table: route_table_igw_to_vpc with Public Subnet
module "rta-internet_to_public_subnet" {
  source    = "./modules/t-aws-rta"
  count     = length(module.public_subnet) #이만큼 반복해서 모듈 생성
  subnet-id = module.public_subnet[count.index].public_subnet-id
  rt-id     = module.route_table-igw_to_vpc.rt-id
}

#Elastic IP
module "eip" {
  source = "./modules/t-aws-eip"
  count  = length(module.private_subnet)
}

#NAT Gateway
module "nat" { #NAT Gateway
  source    = "./modules/t-aws-nat"
  count     = length(module.private_subnet)
  eip-id    = module.eip[count.index].eip-id
  subnet-id = module.public_subnet[count.index].public_subnet-id  #nat는 public subnet에 위치해야 함
}

#Route Table: 0.0.0.0/0 to NAT
module "route_table-internet_to_nat" { 
  source     = "./modules/t-aws-rt"
  count      = length(module.private_subnet)
  vpc-id     = module.vpc.vpc-id
  gateway-id = module.nat[count.index].nat-id
  rt-usage   = "nat"
}

#Associate Route Table: route_table_internet_to_nat with Private Subnet
module "rta-internet_to_nat" { 
  count = length(module.private_subnet)
  source = "./modules/t-aws-rta"
  subnet-id = module.private_subnet[count.index].private_subnet-id
  rt-id = module.route_table-internet_to_nat[count.index].rt-id
}


#key_name이 0827인 key_pair 찾아옴
data "aws_key_pair" "example" {
  key_name           = "0827"
  include_public_key = true

}


################################ EC2 Configuration ###########################
#pirvate ec2는 eks가 관리하니까 private sg 지워도 될 것 같고 public ec2 sg에 rule 추가해야될 것 같은데
#모듈 바꾸면서 지워졌나??

#Public EC2
module "ec2_public" {
  source       = "./modules/t-aws-ec2"
  for_each     = { for i, subnet in module.public_subnet : i => subnet["public_subnet-id"] } # public subnet을 우선으로 반복
  ec2-subnet   = each.value
  ec2-az       = each.key % 2 == 0 ? "ap-northeast-2a" : "ap-northeast-2c"
  ec2-key_name = data.aws_key_pair.example.key_name
  ec2-usage    = "public-${each.key}"
  ec2-sg       = [module.sg-public_ec2.sg-id]
}

#Securty Group for Public EC2
module "sg-public_ec2" { #
  source    = "./modules/t-aws-sg"
  sg-vpc_id = module.vpc.vpc-id 
  sg-name   = "sg_public" #sg 이름에 하이픈('-') 사용 불가
}

#Security Group Rule for  sg-public_ec2
module "sg_rule-public_ec2-outbound" {
  source = "./modules/t-aws-sg_rule-cidr"
  sg_rule-type = "ingress"
  sg_rule-from_port = 22
  sg_rule-to_port = 22
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.sg-public_ec2.sg-id #규칙을 적용할 sg
  sg_rule-cidr_blocks = local.all_ips #허용할 cidr
}
#Security Group for Priavte EC2
#module "sg-private-allow_ssh" { 
#  source = "./modules/t-aws-sg"
#  sg-vpc_id = module.vpc.vpc-id
#  sg-name = "sg_private"
#}

################################ EKS Configuration ###########################
module "eks-role"{
  source = "./modules/t-aws-eks/role/eks_role"
}

module "sg-cluster" {
  source     = "./modules/t-aws-sg"
  sg-vpc_id  = module.vpc.vpc-id
  sg-name    = "sg_cluster"
}

module "sg-node_group" { 
  source     = "./modules/t-aws-sg"
  sg-vpc_id  = module.vpc.vpc-id
  sg-name    = "sg_nodegroup"
}

#클러스터의 추가 sg에서, 노드 그룹 sg의 ingress traffic 허용, 근데 필요한가?
#클러스터 보안 그룹과 클러스터 추가 보안 그룹 차이점 알아보자
module "sg_rule-cluster" {
  source = "./modules/t-aws-sg_rule-sg"
  sg_rule-type = "ingress"
  sg_rule-from_port = 443
  sg_rule-to_port = 443
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.sg-cluster.sg-id #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-node_group.sg-id #허용할 sg
}


#노드 그룹의 sg에서 클러스터 sg의 ingress traffic 허용
module "sg_rule-ng" {
  source = "./modules/t-aws-sg_rule-sg"
  sg_rule-type = "ingress"
  sg_rule-from_port = 443
  sg_rule-to_port = 443
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.sg-node_group.sg-id #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-cluster.sg-id #허용할 sg
}

#클러스터 메인 보안 그룹
module "sg_rule-main_cluster" {
  source = "./modules/t-aws-sg_rule-sg"
  sg_rule-type = "ingress"
  sg_rule-from_port = 443
  sg_rule-to_port = 443
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.eks-cluster.cluster-sg #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-node_group.sg-id #허용할 sg
  depends_on = [module.eks-cluster]
}

output "cluster-main-sg"{
  value = module.eks-cluster.cluster-sg
}


module "sg_rule-cluster-outbound" {
  source = "./modules/t-aws-sg_rule-cidr"
  sg_rule-type = "egress"
  sg_rule-from_port = local.any_port
  sg_rule-to_port = local.any_port
  sg_rule-protocol = local.any_protocol
  sg_rule-sg_id = module.sg-cluster.sg-id #규칙을 적용할 sg
  sg_rule-cidr_blocks = local.all_ips #허용할 cidr
}



module "sg_rule-ng-outbound" {
  source = "./modules/t-aws-sg_rule-cidr"
  sg_rule-type = "egress"
  sg_rule-from_port = local.any_port
  sg_rule-to_port = local.any_port
  sg_rule-protocol = local.any_protocol
  sg_rule-sg_id = module.sg-node_group.sg-id #규칙을 적용할 sg
  sg_rule-cidr_blocks = local.all_ips #허용할 cidr
}

module "eks-cluster"{ 
  source 		= "./modules/t-aws-eks/cluster"
  cluster-name 		= var.cluster-name
  cluster-sg		= [module.sg-cluster.sg-id,]
  cluster-role_arn 	= module.eks-role.arn
  cluster-subnet_ids 	= [ for i in module.private_subnet: i["private_subnet-id"] ]
}

#role of node_group
module "ng-role"{
  source = "./modules/t-aws-eks/role/ng_role"
}

#launch template for node_group
module "lt-ng"{
  source 	= "./modules/t-aws-launch_template"
  cluster-name 	= module.eks-cluster.cluster-name
  lt-sg 	= [module.sg-node_group.sg-id]
  lt-keyname	= data.aws_key_pair.example.key_name
}

module "node_group"{
  source 	   = "./modules/t-aws-eks/ng"
  for_each 	   = {for i, subnet in module.private_subnet: i => subnet}
  cluster-name     = module.eks-cluster.cluster-name
  ng-name 	   = "pracite-ng-${each.key}"
  ng-role_arn      = module.ng-role.arn
  subnet-id        =  [each.value["private_subnet-id"]]
  #key = data.aws_key_pair.example.key_name
  ng-lt_id         = module.lt-ng.lt_id 
  depends_on       = [module.eks-cluster, module.ng-role]
}



output "private_subnet" {
  value = module.private_subnet
}

#private_subnet = [
#  {
#    "private_subnet-id" = "subnet-071e2323dd2ddb05c"
#  },
#  {
#    "private_subnet-id" = "subnet-0d593cfb585c0bd3b"
#  }
output "length-private_subnet" { 
  value = length(module.private_subnet)
}

output "map"{
  value = {for i, subnet in module.private_subnet: i => subnet}
}

#map = {
#  "0" = {
#    "private_subnet-id" = "subnet-07fe372c4eb1889e8"
#  }
#  "1" = {
#    "private_subnet-id" = "subnet-04a40dc056c15bff4"
#  }
#}
#aws-auth configmap을 사용하기 위해 생성했으나, 필요없어짐(액세스 구성 사용)
#module "eks-configmap_auth" { 
#  source = "./modules/t-k8s-configmap"
#  role_arn = module.eks-role.arn
#}

