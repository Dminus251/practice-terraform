resource "aws_route_table_association" "rta" {
  subnet_id = var.subnet-id
  route_table_id = var.rt-id
}
