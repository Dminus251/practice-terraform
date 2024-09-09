resource "helm_release" "alb-ingress-controller"{
  count = 0
  depends_on = [module.eks-cluster.cluster-name]
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
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_ingress_sa_role.arn
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


#eks 클러스터와 OIDC 연동
resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list = ["sts.amazonaws.com"]
  url = module.eks-cluster.url
  thumbprint_list = ["55635cfea6a15f4770cc5ec0977492b318f9b0cc"]  # AWS의 OIDC thumbprint
  #아래 명령으로 나온 값이며, 고정값이라고 함
  #echo | openssl s_client -connect oidc.eks.ap-northeast-2.amazonaws.com:443 2>/dev/null | openssl x509 -fingerprint -noout | sed 's/://g' | awk -F'=' '{print tolower($2)}'
  depends_on = [module.eks-cluster]
}

output "identity" {
  value = module.eks-cluster.identity
}
#identity = tolist([
#  {
#    "oidc" = tolist([
#      {
#        "issuer" = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/5DA9189A26801D7732D5339FB7577A55"
#      },
#    ])
#  },
#])
output "url" {
  value = module.eks-cluster.url
}
#url = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/5DA9189A26801D7732D5339FB7577A55"

resource "aws_iam_role" "alb_ingress_sa_role" {
  name = "alb-ingress-sa-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::992382518527:oidc-provider/oidc.eks.region-code.amazonaws.com/id/15B13976F6F97D987C15AC22C4231799"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.region-code.amazonaws.com/id/15B13976F6F97D987C15AC22C4231799:aud": "sts.amazonaws.com",
                    "oidc.eks.region-code.amazonaws.com/id/15B13976F6F97D987C15AC22C4231799:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ] 
  })
}

resource "aws_iam_policy" "iam_policy-aws-loadbalancer-controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  policy      = file("AWSLoadBalancerControllerIAMPolicy.json")
}

resource "aws_iam_role_policy_attachment" "alb_ingress_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.alb_ingress_sa_role.name
  depends_on = [aws_iam_policy.iam_policy-aws-loadbalancer-controller]
}


resource "kubernetes_service_account" "example" {
  metadata {
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
    }
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::992382518527:role/${aws_iam_role.alb_ingress_sa_role.name}"
    }
  }
}

