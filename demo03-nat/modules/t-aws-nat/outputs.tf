output "nat-id" {
  value =  [for i in aws_nat_gateway.nat: i.id]
}
