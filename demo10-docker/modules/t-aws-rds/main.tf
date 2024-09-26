resource "aws_db_instance" "default" {
  allocated_storage    = var.rds-allocated_storage
  db_name              = var.rds-db_name
  engine               = var.rds-engine
  engine_version       = var.rds-engine_version
  instance_class       = var.rds-instance_class
  username             = var.rds-username
  password             = var.rds-password
  skip_final_snapshot  = var.rds-skip_final_snapshot
  db_subnet_group_name = var.rds-db_subnet_group_name
}
