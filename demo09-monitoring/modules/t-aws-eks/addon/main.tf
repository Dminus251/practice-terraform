resource "aws_eks_addon" "addon" {
  cluster_name = var.addon-cluster_name
  addon_name   = var.addon-name
  service_account_role_arn = var.addon-role
}
