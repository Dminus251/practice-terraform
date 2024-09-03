output "endpoint" {
  value = aws_eks_cluster.example.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.example.certificate_authority[0].data
}

output "test" {
  value = aws_eks_cluster.example.certificate_authority
}
output "cluster-name" {
  value = var.cluster-name
}

output "cluster-sg" {
  value = aws_eks_cluster.example.vpc_config[0].cluster_security_group_id
}
