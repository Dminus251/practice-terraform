resource "aws_subnet" "public_subnets"{
  vpc_id = var.vpc-id
  cidr_block = var.public_subnet-cidr
  availability_zone = var.public_subnet-az
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet-name
    "kubernetes.io/role/elb" = "1"
  }
}


