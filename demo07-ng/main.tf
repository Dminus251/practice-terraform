locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

module "vpc" { #VPC
  source = "./modules/t-aws-vpc"
}

module "public_subnet" { #Public Subnet
  source 	     = "./modules/t-aws-public_subnet"
  count 	     = length(var.public_subnet-cidr)
  vpc-id	     = module.vpc.vpc-id
  public_subnet-cidr = var.public_subnet-cidr[count.index]
  public_subnet-az   = count.index % 2 == 0 ? var.public_subnet-az[0] : var.public_subnet-az[1]
  public_subnet-name = var.public_subnet-name[count.index]
}

module "private_subnet" { #Private Subnet
  source 	      = "./modules/t-aws-private_subnet"
  count 	      = length(var.private_subnet-cidr)
  vpc-id 	      = module.vpc.vpc-id
  private_subnet-cidr = var.private_subnet-cidr[count.index]
  private_subnet-az   = count.index % 2 == 0 ? var.private_subnet-az[0] : var.private_subnet-az[1]
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
#  count = length(module.public_subnet) + length(module.private_subnet)
#  ec2-subnet = count.index < 2 ? module.public_subnet[count.index] : module.private_subnet[count.index-2] #index 내 연산 불가
#  ec2-az =  count.index % 2 == 0 ? "ap-northeast-2a" : "ap-northeast-2c"
#  ec2-key_name = "0828"
#  ec2-usage = count.index < 2 ? "public-${count.index}" : "private-${count.index}"
#}

#key_name이 0827인 key_pair 찾아옴
data "aws_key_pair" "example" {
  key_name           = "0827"
  include_public_key = true

}
module "ec2_public" {
  source = "./modules/t-aws-ec2"
  for_each = { for i, subnet in module.public_subnet : i => subnet["public_subnet-id"] } # public subnet을 우선으로 반복
  ec2-subnet   = each.value
  ec2-az       = each.key % 2 == 0 ? "ap-northeast-2a" : "ap-northeast-2c"
  ec2-key_name = data.aws_key_pair.example.key_name
  ec2-usage    = "public-${each.key}"
  ec2-sg       = [module.sg-public-allow_ssh.sg-id]
}


module "ec2_private" {
  source = "./modules/t-aws-ec2"
  for_each = { for i, subnet in module.private_subnet : i => subnet["private_subnet-id"]}
  ec2-subnet   = each.value
  ec2-az       = each.key % 2 == 0 ? "ap-northeast-2a" : "ap-northeast-2c"
  ec2-key_name = data.aws_key_pair.example.key_name
  ec2-usage    = "private-${each.key}"
  ec2-sg       = [module.sg-private-allow_ssh.sg-id]
}

#public subnet의 instance에 할당. 0.0.0.0/0에서 ssh를 허용함
module "sg-public-allow_ssh" { #0.0.0.0/0에서 ssh 허용
  source = "./modules/t-aws-sg"
  sg-vpc_id = module.vpc.vpc-id
  sg-name = "sg_public" #sg 이름에 하이픈('-') 사용 불가
}

#private subnet의 instanec에 할당. public subnet의 cidr에서의 ssh 허용
module "sg-private-allow_ssh" { #public subnet에서의 ssh 허용
  source = "./modules/t-aws-sg"
  sg-vpc_id = module.vpc.vpc-id
  sg-name = "sg_private"
}

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

resource "aws_security_group_rule" "cluster_outbound" {
  type              = "egress"
  from_port         = 0 #protocol이 -1인 경우 0으로 고정해야 함
  to_port           = 0 #마찬가지
  protocol          = "-1"  # -1 means all protocols
  security_group_id = module.sg-cluster.sg-id  # 클러스터 보안 그룹
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"  # -1 means all protocols
  security_group_id = module.sg-node_group.sg-id  # 노드 그룹 보안 그룹
  cidr_blocks       = ["0.0.0.0/0"]
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
  source 		 = "./modules/t-aws-launch_template"
  cluster-name = module.eks-cluster.cluster-name
  lt-sg = [module.sg-node_group.sg-id]
}

module "node_group"{
  source 	   = "./modules/t-aws-eks/ng"
  for_each 	   = {for i, subnet in module.private_subnet: i => subnet}
  cluster-name     = module.eks-cluster.cluster-name
  ng-name 	   = "pracite-ng-${each.key}"
  ng-role_arn      = module.ng-role.arn
  subnet-id        =  [each.value["private_subnet-id"]]
  #key = data.aws_key_pair.example.key_name
  ng-lt_id = module.lt-ng.lt_id 
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

