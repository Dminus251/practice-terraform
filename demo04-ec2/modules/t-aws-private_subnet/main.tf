resource "aws_subnet" "private_subnets"{
  vpc_id = var.vpc-id
  cidr_block = var.private_subnet-cidr
  availability_zone = var.private_subnet-az
  tags = {
    Name = var.private_subnet-name
  }
}

