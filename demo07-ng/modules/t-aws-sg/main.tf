resource "aws_security_group" "sg" {
  name = var.sg-name
  vpc_id = var.sg-vpc_id
}
