provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region     = var.AWS_REGION
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  host                   = var.create_cluster ? module.eks-cluster[0].endpoint : ""
  token                  = var.create_cluster ? data.aws_eks_cluster_auth.example[0].token : ""
  cluster_ca_certificate = var.create_cluster ? base64decode(module.eks-cluster[0].kubeconfig-certificate-authority-data) : ""
}



provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    host                   = var.create_cluster ? module.eks-cluster[0].endpoint : ""
    token                  = var.create_cluster ? data.aws_eks_cluster_auth.example[0].token : ""
    cluster_ca_certificate = var.create_cluster ? base64decode(module.eks-cluster[0].kubeconfig-certificate-authority-data) : ""
  }
}

