#k8s provider의 token을 얻는 데 사용
data "aws_eks_cluster_auth" "example" {
  name = module.eks-cluster.cluster-name
  depends_on = [module.eks-cluster] #클러스터 먼저 생성돼야 cluster-name output 사용 가능
}

#k8s provider의 cluster_ca_certificate를 얻는 데 사용
data "aws_eks_cluster" "example" {
  name = module.eks-cluster.cluster-name
  depends_on = [module.eks-cluster]
}

