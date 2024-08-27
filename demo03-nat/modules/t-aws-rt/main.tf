resource "aws_route_table" "internet" {
  vpc_id = var.vpc-id

  route { #route 1: 모든 트래픽을 igw로
    cidr_block = "0.0.0.0/0" #from
    gateway_id = var.gateway-id   #to
  }

  tags = {
    Name = var.rt-name
  }
}
