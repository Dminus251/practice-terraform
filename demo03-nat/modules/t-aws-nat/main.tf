resource "aws_nat_gateway" "nat" {
 
  allocation_id = var.eip-id #eip의 id
  subnet_id     = var.subnet-id#subnet id

  tags = {
    Name = var.nat-name
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  #depends_on = [aws_internet_gateway.example]
}
