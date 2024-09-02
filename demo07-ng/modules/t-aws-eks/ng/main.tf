resource "aws_eks_node_group" "example" {
  cluster_name    = var.cluster-name
  node_group_name = var.ng-name
  node_role_arn   = var.ng-role_arn
  subnet_ids      = var.subnet-id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  remote_access {
    ec2_ssh_key = var.key
  }
  launch_template {
    name = var.worker_node-name
  }
}
