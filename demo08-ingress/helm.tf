resource "helm_release" "alb-ingress-controller"{
  count = 1
  depends_on = [module.eks-cluster, module.public_subnet]
  repository = "https://aws.github.io/eks-charts"
  name = "aws-load-balancer-controller"
  chart = "aws-load-balancer-controller"
  version = "1.8.2"
  namespace = "kube-system"
  

  set {
	name  = "clusterName"
	value = module.eks-cluster.cluster-name
  }

  set {
	name  = "region"
	value = var.AWS_REGION
  }

  set {
	name  = "vpcId"
	value = module.vpc.vpc-id
  }

  set {
	name  = "rbac.create"
	value = "true" #if true, create and use RBAC resource
  }

  set {
	name  = "serviceAccount.create"
	value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
	name  = "createIngressClassResource"
	value = "true"
  }

  set {
    name  = "webhook.service.port"
    value = "443"
  }

  set {
    name  = "webhook.service.targetPort"
    value = "9443"
  }
}

output "oidc_url" {
  value = module.eks-cluster.oidc_url
}
#oidc_url = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/7F754942AF1A6F2F39B3DF446AB717FA"

output "oidc_url_without_https" {
  value = module.eks-cluster.oidc_url_without_https
}
#oidc_url_without_https = "oidc.eks.ap-northeast-2.amazonaws.com/id/7F754942AF1A6F2F39B3DF446AB717FA"

