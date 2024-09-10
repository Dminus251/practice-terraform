#resource "aws_iam_role" "alb_ingress_sa_role2" {
#  count = 0
#  name = "alb-ingress-sa-role"
#
#  assume_role_policy = jsonencode({
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Principal": {
#                "Federated": "arn:aws:iam::992382518527:oidc-provider/${module.eks-cluster.oidc_url_without_https}"
#            },
#            "Action": "sts:AssumeRoleWithWebIdentity",
#            "Condition": {
#                "StringEquals": {
#                    "${module.eks-cluster.oidc_url_without_https}:aud": "sts.amazonaws.com", #인증 요청 대상
# 		    "${module.eks-cluster.oidc_url_without_https}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
#                }
#            }
#        }
#    ] 
#  })
#}

#resource "aws_iam_policy" "iam_policy-aws-loadbalancer-controller2" {
#  count = 0
#  name        = "AWSLoadBalancerControllerIAMPolicy"
#  policy      = file("AWSLoadBalancerControllerIAMPolicy.json")
#}

#resource "aws_iam_role_policy_attachment" "alb_ingress_policy_attach2" {
#  count = 0
#  policy_arn = aws_iam_policy.iam_policy-aws-loadbalancer-controller.arn
#  role       = aws_iam_role.alb_ingress_sa_role.name
#  depends_on = [aws_iam_policy.iam_policy-aws-loadbalancer-controller]
#}


resource "aws_iam_role" "alb_ingress_sa_role" {
  name = var.role-alc_role_name

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::992382518527:oidc-provider/${var.role-alc-oidc_without_https}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${var.role-alc-oidc_without_https}:aud": "sts.amazonaws.com", #인증 요청 대상
 		    "${var.role-alc-oidc_without_https}:sub": "system:serviceaccount:${var.role-alc-namespace}:${var.role-alc-sa_name}"
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
  policy_arn = aws_iam_policy.iam_policy-aws-loadbalancer-controller.arn
  role       = aws_iam_role.alb_ingress_sa_role.name
  depends_on = [aws_iam_policy.iam_policy-aws-loadbalancer-controller, aws_iam_role.alb_ingress_sa_role]
}
