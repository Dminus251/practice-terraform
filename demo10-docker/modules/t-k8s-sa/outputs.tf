output "sa-namespace"{
  value = kubernetes_service_account.example.metadata[0].namespace
}
output "sa-name"{
  value = kubernetes_service_account.example.metadata[0].name
}
