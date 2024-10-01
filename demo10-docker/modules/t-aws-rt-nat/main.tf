resource "aws_route_table" "internet" {
  vpc_id = var.vpc-id

  route {
    cidr_block = var.cidr_block #from
    nat_gateway_id = var.gateway-id   #to
  }

  tags = {
    Name = "prctice-rt-${var.rt-usage}"
  }
}
