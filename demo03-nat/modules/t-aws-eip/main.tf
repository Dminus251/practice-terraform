resource "aws_eip" "eip" {
  count = var.private_subnet-length
  tags = {
    Name = var.eip-name
  }
}
