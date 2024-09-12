resource "kubernetes_service_account" "example"{
  metadata{
    labels = var.sa-labels
    name = var.sa-name
    namespace = var.sa-namespace
    annotations = var.sa-annotations
  }
}

#output "sa-metadata"{
#  value = resource.kubernetes_service_account.example.metadata
#}

#예시 sa-metadata = tolist([
#  {
#    "annotations" = tomap({
#      "eks.amazonaws.com/role-arn" = "arn:aws:iam::992382518527:role/alb-ingress-sa-role"
#    })
#    "generate_name" = ""
#    "generation" = 0
#    "labels" = tomap({
#      "app.kubernetes.io/component" = "controller"
#      "app.kubernetes.io/name" = "aws-load-balancer-controller"
#    })
#    "name" = "aws-load-balancer-controller"
#    "namespace" = "kube-system"
#    "resource_version" = "687"
#    "uid" = "8fee6f31-b516-40fc-8e42-afe87e13688a"
#  },
#])
