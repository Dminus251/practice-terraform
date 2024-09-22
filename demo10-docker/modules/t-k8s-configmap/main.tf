resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOF
- rolearn: var.role_arn
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
EOF
    mapUsers = <<EOF
- userarn: "arn:aws:iam::992382518527:user/eks-user" #일단 하드코딩
  username: "eks-user"
  groups:
    - system:masters
EOF
  }
}
