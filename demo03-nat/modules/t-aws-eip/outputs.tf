output "eip-id" {
  value = [for i in aws_eip.eip: i.id]
}
