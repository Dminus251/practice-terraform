resource "aws_nat_gateway" "nat" {
 
  count = var.private_subnet-length #private subnet 길이만큼 반복해서 생성

  allocation_id = var.eip-id[count.index] #eip의 id
  subnet_id     = var.private_subnet-id[count.index] #subnet id

  tags = {
    Name = var.nat-name
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  #depends_on = [aws_internet_gateway.example]
}
