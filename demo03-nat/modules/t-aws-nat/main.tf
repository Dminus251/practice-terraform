resource "aws_nat_gateway" "nat" {
 
  allocation_id = var.eip-id #eip의 id
  subnet_id     = var.subnet-id #subnet id

  tags = {
    Name = var.nat-name
  }
}
