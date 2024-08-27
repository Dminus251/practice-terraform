resource "aws_subnet" "private_subnets"{
  vpc_id = var.vpc-id

  for_each = var.private_subnets
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key
  }
}

