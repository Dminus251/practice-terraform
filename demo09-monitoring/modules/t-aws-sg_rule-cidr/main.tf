resource "aws_security_group_rule" "sg_rule" {
  type              = var.sg_rule-type
  description	    = var.description
  from_port         = var.sg_rule-from_port
  to_port           = var.sg_rule-to_port
  protocol          = var.sg_rule-protocol
  security_group_id = var.sg_rule-sg_id  # 규칙을 적용할 sg
  cidr_blocks	    = var.sg_rule-cidr_blocks #허용할 cidr block
}
