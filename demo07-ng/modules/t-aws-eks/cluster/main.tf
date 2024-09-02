resource "aws_eks_cluster" "example" {
  name     = var.cluster-name
  role_arn = var.cluster-role_arn
  
  vpc_config {
    subnet_ids = var.cluster-subnet_ids
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
}

resource "terraform_data" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ap-northeast-2 --name ${var.cluster-name}"
  }

  depends_on = [aws_eks_cluster.example]
}
