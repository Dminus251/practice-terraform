#alb-ingress-controller Artifact Hub https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
#ref blog https://blog.searce.com/using-helm-with-terraform-to-deploy-aws-load-balancer-controller-on-aws-eks-84ea102352f2

resource "helm_release" "alb-ingress-controller"{
  depends_on = [module.eks-cluster.cluster-name]
  name = "alb-ingress-controller"
  chart = "alb-ingress-controller"
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
	value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "sa-alb-ingress-controller"
  }

  set {
	name  = "createIngressClassResource"
	value = "true"
  }
}
