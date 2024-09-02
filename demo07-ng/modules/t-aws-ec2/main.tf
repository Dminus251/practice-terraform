resource "aws_instance" "ec2" {
  ami           = var.ami-ubuntu-id
  instance_type = "t2.micro"
  subnet_id     = var.ec2-subnet
  availability_zone = var.ec2-az
  key_name = var.ec2-key_name
  security_groups = var.ec2-sg
  tags = {
    Name = "ec2-${var.ec2-usage}"
  }
}
