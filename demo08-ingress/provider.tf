provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region     = var.AWS_REGION
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  
  #Credentials config:
  host                   = module.eks-cluster.endpoint
  token                  = data.aws_eks_cluster_auth.example.token
  cluster_ca_certificate = base64decode(module.eks-cluster.kubeconfig-certificate-authority-data)
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  
    #Credentials config:
    host                   = module.eks-cluster.endpoint
    token                  = data.aws_eks_cluster_auth.example.token
    cluster_ca_certificate = base64decode(module.eks-cluster.kubeconfig-certificate-authority-data)
  }
}
