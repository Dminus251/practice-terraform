resource "aws_eks_cluster" "example" {
  name     = "example"
  role_arn = var.cluster-role_arn

  vpc_config {
    subnet_ids = var.cluster-subnet_ids
  }

}

