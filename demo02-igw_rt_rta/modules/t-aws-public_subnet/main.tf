resource "aws_subnet" "public_subnets"{
  vpc_id = var.vpc-id

  for_each = var.public_subnets
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = {
    Name = each.key
  }
}


