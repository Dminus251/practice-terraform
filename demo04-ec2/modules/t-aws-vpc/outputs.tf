output "vpc-id" { 
  value = aws_vpc.main.id
}

output "vpc-cidr" {
  value = var.vpc-cidr
}
