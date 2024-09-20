#기존 main.tf에서 가용성을 없애고 비용을 줄인 파일입니다.
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
  count = 1
  source    = "./modules/t-aws-nat"
  eip-id    = module.eip[count.index].eip-id
  subnet-id = module.public_subnet[count.index].public_subnet-id  #nat는 public subnet에 위치해야 함
}


#Route Table: 0.0.0.0/0 to NAT
module "route_table-internet_to_nat" { 
  source     = "./modules/t-aws-rt"
  count      = 1
  vpc-id     = module.vpc.vpc-id
  gateway-id = module.nat[count.index].nat-id
  rt-usage   = "nat"
}

#Associate Route Table: route_table_internet_to_nat with Private Subnet
module "rta-internet_to_nat" { 
  count = 1
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

#Security Group Rule for sg-public_ec2: Allow Ingress SSH Traffic from Internet
module "sg_rule-public_ec2-allow_ingress_ssh-internet" {
  source = "./modules/t-aws-sg_rule-cidr"
  sg_rule-type = "ingress"
  sg_rule-from_port = 22
  sg_rule-to_port = 22
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.sg-public_ec2.sg-id #규칙을 적용할 sg
  sg_rule-cidr_blocks = local.all_ips #허용할 cidr
}

#Security Group Rule for sg-public_ec2: Allow Egress all Traffic
module "sg_rule-public_ec2-allow_egress-all_traffic" {
  source = "./modules/t-aws-sg_rule-cidr"
  sg_rule-type = "egress"
  sg_rule-from_port = local.any_port
  sg_rule-to_port = local.any_port
  sg_rule-protocol = local.any_protocol
  sg_rule-sg_id = module.sg-public_ec2.sg-id #규칙을 적용할 sg
  sg_rule-cidr_blocks = local.all_ips #허용할 cidr
}
################################ EKS Configuration ###########################
module "eks-cluster"{ 
  source 		= "./modules/t-aws-eks/cluster"
  cluster-name 		= var.cluster-name
  cluster-sg		= [module.sg-cluster.sg-id,]
  cluster-role_arn 	= module.eks-role.arn
  cluster-subnet_ids 	= [ for i in module.private_subnet: i["private_subnet-id"] ]
}

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

#module "sg_rule-cluster" {
#  source 	       = "./modules/t-aws-sg_rule-sg"
#  sg_rule-type         = "ingress"
#  sg_rule-from_port    = 443
#  sg_rule-to_port      = 443
#  sg_rule-protocol     = "tcp"
#  sg_rule-sg_id	       = module.sg-cluster.sg-id #규칙을 적용할 sg
#  sg_rule-source_sg_id = module.sg-node_group.sg-id #허용할 sg
#}


#노드 그룹의 sg에서 클러스터 sg의 ingress traffic 허용
module "sg_rule-ng-allow_https-from_cluster" {
  source 	       = "./modules/t-aws-sg_rule-sg"
  sg_rule-type         = "ingress"
  sg_rule-from_port    = 443
  sg_rule-to_port      = 443
  sg_rule-protocol     = "tcp"
  sg_rule-sg_id        = module.sg-node_group.sg-id #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-cluster.sg-id #허용할 sg
}

#노드 그룹의 sg에서 public subnet의 ssh ingress 허용
module "sg_rule-ng-allow_ssh-from_public_subnet" {
  source 	       = "./modules/t-aws-sg_rule-sg"
  sg_rule-type 	       = "ingress"
  sg_rule-from_port    = 22
  sg_rule-to_port      = 22
  sg_rule-protocol     = "tcp"
  sg_rule-sg_id        = module.sg-node_group.sg-id #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-public_ec2.sg-id #허용할 sg
}

module "sg_rule-ng-allow_Kubelet" {
  source 	       = "./modules/t-aws-sg_rule-sg"
  description	       = "Kubelet API"
  sg_rule-type 	       = "ingress"
  sg_rule-from_port    = 10250
  sg_rule-to_port      = 10250
  sg_rule-protocol     = "tcp"
  sg_rule-sg_id        = module.sg-node_group.sg-id #규칙을 적용할 sg
  sg_rule-source_sg_id = module.eks-cluster.cluster-sg #허용할 sg
}


module "sg_rule-ng-allow_kube-porxy" {
  source 	       = "./modules/t-aws-sg_rule-sg"
  description	       = "kube-proxy"
  sg_rule-type 	       = "ingress"
  sg_rule-from_port    = 10256
  sg_rule-to_port      = 10256
  sg_rule-protocol     = "tcp"
  sg_rule-sg_id        = module.sg-node_group.sg-id #규칙을 적용할 sg
  sg_rule-source_sg_id = module.eks-cluster.cluster-sg #허용할 sg
}


module "sg_rule-ng-allow_NodePort" {
  source 	       = "./modules/t-aws-sg_rule-sg"
  description	       = "NodePort Services"
  sg_rule-type 	       = "ingress"
  sg_rule-from_port    = 30000
  sg_rule-to_port      = 32767
  sg_rule-protocol     = "tcp"
  sg_rule-sg_id        = module.sg-node_group.sg-id #규칙을 적용할 sg
  sg_rule-source_sg_id = module.eks-cluster.cluster-sg #허용할 sg
}


module "sg_rule-ng-allow_webhook" {
  source 	       = "./modules/t-aws-sg_rule-sg"
  description	       = "allow webhook"
  sg_rule-type 	       = "ingress"
  sg_rule-from_port    = 9443
  sg_rule-to_port      = 9443
  sg_rule-protocol     = "tcp"
  sg_rule-sg_id        = module.sg-node_group.sg-id #규칙을 적용할 sg
  sg_rule-source_sg_id = module.eks-cluster.cluster-sg #허용할 sg
}





#클러스터 메인 보안 그룹에서 노드 그룹의 https ingress 허용
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

module "sg_rule-main_cluster-allow_kube_API" { 
  source = "./modules/t-aws-sg_rule-sg"
  description = "Kubernetes API server"
  sg_rule-type = "ingress"
  sg_rule-from_port = 6443
  sg_rule-to_port = 6443
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.eks-cluster.cluster-sg #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-node_group.sg-id #허용할 sg
  depends_on = [module.eks-cluster]
}


module "sg_rule-main_cluster-allow_etcd" { 
  source = "./modules/t-aws-sg_rule-sg"
  description = "etcd server clien API"
  sg_rule-type = "ingress"
  sg_rule-from_port = 2379
  sg_rule-to_port = 2380
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.eks-cluster.cluster-sg #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-node_group.sg-id #허용할 sg
  depends_on = [module.eks-cluster]
}


module "sg_rule-main_cluster-allow_kubelet" { 
  source = "./modules/t-aws-sg_rule-sg"
  description = "kubelet API"
  sg_rule-type = "ingress"
  sg_rule-from_port = 10250
  sg_rule-to_port = 10250
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.eks-cluster.cluster-sg #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-node_group.sg-id #허용할 sg
  depends_on = [module.eks-cluster]
}


module "sg_rule-main_cluster-allow_kube-scheduler" { 
  source = "./modules/t-aws-sg_rule-sg"
  description = "kube-scheduler"
  sg_rule-type = "ingress"
  sg_rule-from_port = 10259
  sg_rule-to_port = 10259
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.eks-cluster.cluster-sg #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-node_group.sg-id #허용할 sg
  depends_on = [module.eks-cluster]
}


module "sg_rule-main_cluster-allow_kube-controller-manager" { 
  source = "./modules/t-aws-sg_rule-sg"
  description = "kube-controller-manager"
  sg_rule-type = "ingress"
  sg_rule-from_port = 10257
  sg_rule-to_port = 10257
  sg_rule-protocol = "tcp"
  sg_rule-sg_id = module.eks-cluster.cluster-sg #규칙을 적용할 sg
  sg_rule-source_sg_id = module.sg-node_group.sg-id #허용할 sg
  depends_on = [module.eks-cluster]
}

module "sg_rule-main_cluster-allow_webhook" { 
  source = "./modules/t-aws-sg_rule-sg"
  description = "allow webhook"
  sg_rule-type = "ingress"
  sg_rule-from_port = 9443
  sg_rule-to_port = 9443
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


#role of node_group
module "ng-role"{
  source = "./modules/t-aws-eks/role/ng_role"
}

#launch template for node_group
module "lt-ng"{
  source 	= "./modules/t-aws-launch_template"
  lt-sg 	= [module.sg-node_group.sg-id]
  lt-key_name	= data.aws_key_pair.example.key_name
  cluster-name 	= module.eks-cluster.cluster-name
  aws_access_key_id = var.AWS_ACCESS_KEY
  aws_access_key_secret = var.AWS_SECRET_KEY
  region = var.AWS_REGION
}

module "node_group"{
  source 	   = "./modules/t-aws-eks/ng"
  cluster-name     = module.eks-cluster.cluster-name
  ng-name 	   = "pracite-ng-0"
  ng-role_arn      = module.ng-role.arn
  subnet-id        = [module.private_subnet[0].private_subnet-id]
  ng-lt_id         = module.lt-ng.lt_id 
  depends_on       = [module.eks-cluster, module.ng-role]
}

#OCID 공급자 연결
module "openid_connect_provider"{
  source ="./modules/t-aws-openid_connect_provider"
  client_id_list = ["sts.amazonaws.com"]
  url = module.eks-cluster.oidc_url
  depends_on = [module.eks-cluster]
}

#add on 
module "addon-aws-ebs-csi-driver"{
  source = "./modules/t-aws-eks/addon/"
  addon-cluster_name = module.eks-cluster.cluster-name
  addon-name = "aws-ebs-csi-driver"
  addon-role = module.role-ecd-sa.arn
  depends_on = [module.node_group]
}
############################ Helm Configuration ###########################

#Role for aws-loadbalacner-controller sa
module "role-alc-sa"{
  source = "./modules/t-aws-eks/role/alc"
  role-alc_role_name = "alb-ingress-sa-role"
  role-alc-oidc_without_https = module.eks-cluster.oidc_url_without_https
  role-alc-namespace = module.sa-alc.sa-namespace
  role-alc-sa_name = module.sa-alc.sa-name
  depends_on = [module.eks-cluster]
}

#Service Account for aws-loadbalacner-controller
module "sa-alc"{ 
  source = "./modules/t-k8s-sa"
  sa-labels = {
    "app.kubernetes.io/component" = "controller" #구성 요소
    "app.kubernetes.io/name" = "aws-load-balacner-controller" #애플리케이션 이름
  }
  sa-name = "aws-load-balancer-controller"
  sa-namespace = "kube-system"
  sa-annotations = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::992382518527:role/alb-ingress-sa-role"
  }
  depends_on = [module.eks-cluster]
}


#Role of EBS-CSI-DRIVER sa
module "role-ecd-sa"{
  source = "./modules/t-aws-eks/role/ebs-csi-driver"
  role-ecd_role_name = "ebs-csi-controller-sa"
  role-ecd-oidc_without_https = module.eks-cluster.oidc_url_without_https
  role-ecd-namespace = "kube-system"
  role-ecd-sa_name = "ebs-csi-controller-sa"
  depends_on = [module.eks-cluster]
}

#Service Account for EBS-CSI-Driver
#module "sa-ecd"{
#  source = "./modules/t-k8s-sa"
#  sa-labels = {
#    "app.kubernetes.io/component" = "controller" #구성 요소
#    "app.kubernetes.io/name" = "ebs-csi-controller" #애플리케이션 이름
#    
#  }
#  sa-name = "ebs-csi-controller-sa"
#  sa-namespace = "kube-system"
#  sa-annotations = {
#    "eks.amazonaws.com/role-arn" = "arn:aws:iam::992382518527:role/ebs-csi-controller-sa"
#  }
#  depends_on = [module.eks-cluster]
#}

data "aws_route53_zone" "route53" {
  name = "youngkyu.me"
}

output "route53" {
  value = data.aws_route53_zone.route53
}
