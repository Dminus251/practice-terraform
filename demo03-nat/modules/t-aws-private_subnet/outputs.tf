output "private_subnet-length"{
  value = length(var.private_subnets)
}

output "private_subnet-id" {
  value = [for i in aws_subnet.private_subnets: i.id]
}

