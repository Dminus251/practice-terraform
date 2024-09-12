output "public_subnet-test"{
  value = "test"
}

output "public_subnet-id" {
   value = aws_subnet.public_subnets.id
}


