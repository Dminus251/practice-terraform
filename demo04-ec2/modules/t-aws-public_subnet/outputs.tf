#output "public_subnet-length"{
#  value = length(var.public_subnets)
#}

#output "public_subnet-id" {
#  value = [for i in aws_subnet.public_subnets: i.id]
#}
output "public_subnet-id" {
   value = aws_subnet.public_subnets.id
}


