resource "aws_route_table_association" "pulic" {

  count = var.public_subnet-length
  subnet_id = var.public_subnet-id[count.index]
  route_table_id = var.rt-id
}
