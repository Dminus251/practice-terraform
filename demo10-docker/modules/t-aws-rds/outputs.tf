output "vpc_security_group_ids" {
  value = aws_db_instance.default.vpc_security_group_ids
}

output "db_endpoint" {
  value = aws_db_instance.default.endpoint
}


output "db_name" {
  value = aws_db_instance.default.db_name
}

output "db_user" {
  value = aws_db_instance.default.username
}


output "db_password" {
  value = aws_db_instance.default.password
}
