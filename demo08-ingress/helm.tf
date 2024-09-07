#│ Error: could not download chart: non-absolute URLs should be in form of repo_name/path_to_chart, got: alb-ingress-controller
#│
#│   with helm_release.alb-ingress-controller,
#│   on helm.tf line 4, in resource "helm_release" "alb-ingress-controller":
#│    4: resource "helm_release" "alb-ingress-controller"{
#│

#alb-ingress-controller Artifact Hub https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
#ref blog https://blog.searce.com/using-helm-with-terraform-to-deploy-aws-load-balancer-controller-on-aws-eks-84ea102352f2

resource "helm_release" "alb-ingress-controller"{
  depends_on = [module.eks-cluster.cluster-name]
  repository = "https://aws.github.io/eks-charts"
  name = "aws-load-balancer-controller"
  chart = "aws-load-balancer-controller"
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
