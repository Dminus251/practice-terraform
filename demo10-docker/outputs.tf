output "db_endpoint" {
  value = var.create_rds ? module.rds[0].db_endpoint : null
}
output "db_name" {
  value = var.create_rds ? module.rds[0].db_name : null
}

output "db_user" {
  value = var.create_rds ? module.rds[0].db_user : null
}

output "db_password" {
  value = var.create_rds ? module.rds[0].db_password : null
  sensitive = true
}
