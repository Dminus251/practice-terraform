resource "aws_security_group" "sg" {
  name = var.sg-name
  vpc_id = var.sg-vpc_id

#  ingress {
#    from_port       = var.ingress-from_port
#    to_port         = var.ingress-to_port
#    protocol        = var.ingress-protocol
#    cidr_blocks	    = var.ingress-cidr_blocks
#    security_groups = var.ingress-security_group
#  }
  ingress {
    from_port       = var.ingress["from_port"]
    to_port         = var.ingress["to_port"]
    protocol        = var.ingress["protocol"]
    cidr_blocks	    = var.ingress["cidr_blocks"]
    security_groups = var.ingress["security_groups"]
  }
  #나가는 건 딱히 제한하지 않아도 될 듯..?
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
}

