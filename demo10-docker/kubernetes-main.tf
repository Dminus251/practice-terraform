#Ingress for Prometheus
resource "kubernetes_ingress_v1" "ingress-prometheus" { 
  count			= var.create_cluster ? 1 : 0
  depends_on = [module.eks-cluster, module.node_group, helm_release.prometheus, kubernetes_service_v1.service-prometheus]
  metadata {
    name = "ingress-prometheus"
    namespace = "monitoring"
    annotations = {
      "alb.ingress.kubernetes.io/scheme" =  "internet-facing"
      "alb.ingress.kubernetes.io/target-type" =  "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/graph"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      host = "prometheus.${var.DOMAIN}"
      http {
        path {
          path_type = "Prefix"
          path = "/"
          backend {
            service{
  	      name = "service-prometheus"
              port {
                number = 9090
              }
            }
          }

        }

      }
    }
  }
}

#Service for Prometheus
resource "kubernetes_service_v1" "service-prometheus" {
  count			= var.create_cluster ? 1 : 0
  depends_on = [module.eks-cluster, module.node_group, helm_release.prometheus]
  metadata {
    name = "service-prometheus"
    namespace = "monitoring"
  }
  spec {
    type = "NodePort"
    selector = {
      "app.kubernetes.io/name" =  "prometheus"
    }
    port {
      port        = 9090
      target_port = 9090
      protocol = "TCP"
    }
  }
}


#Ingress for Grafana
resource "kubernetes_ingress_v1" "ingress-grafana" { 
  count			= var.create_cluster ? 1 : 0
  depends_on = [module.eks-cluster, module.node_group, helm_release.grafana, kubernetes_service_v1.service-grafana]
  metadata {
    name = "ingress-grafana"
    namespace = "monitoring"
    annotations = {
      "alb.ingress.kubernetes.io/scheme" =  "internet-facing"
      "alb.ingress.kubernetes.io/target-type" =  "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      host = "grafana.${var.DOMAIN}"
      http {
        path {
          path_type = "Prefix"
          path = "/"
          backend {
            service{
  	      name = "service-grafana"
              port {
                number = 3000
              }
            }
          }

        }

      }
    }
  }
}

#terraform_outputs.json 파일 생성. depends_on에 꼭!!! 모든 output 넣을 것
resource "terraform_data" "update-output_json" {
  depends_on = [module.rds, module.rds[0].db_endpoint, module.rds[0].db_name, module.rds[0].db_user, module.rds[0].db_password]
  provisioner "local-exec" {
    command = "terraform output -json > ./yyk-server/terraform_outputs.json"
  }
}

#Pod for my crud image
resource "kubernetes_pod" "pod-crud" {
  count			= var.create_cluster ? 1 : 0
  metadata {
    name = "pod-crud"
    labels = {
      "app.kubernetes.io/name" =  "crud"
    }
  }

  spec {
    container {
      image = "dminus251/test:latest"  # 근데 이미지는 빌드마다 달라짐(output때매 ..)
      name  = "practice"

      port {
        container_port = 5000 
      }
    }
  }
}

#Service for pod-crud
resource "kubernetes_service_v1" "service-crud" {
  count			= var.create_cluster ? 1 : 0
  depends_on = [module.eks-cluster, module.node_group]
  metadata {
    name = "service-crud"
    namespace = "monitoring"
  }
  spec {
    type = "NodePort"
    selector = {
      "app.kubernetes.io/name" =  "crud"
    }
    port {
      port        = 5000 
      target_port = 5000
      protocol = "TCP"
    }
  }
}

#Ingress for service-crud
resource "kubernetes_ingress_v1" "ingress-crud" { 
  count			= var.create_cluster ? 1 : 0
  depends_on = [module.eks-cluster, module.node_group, helm_release.grafana, kubernetes_service_v1.service-crud]
  metadata {
    name = "ingress-grafana"
    namespace = "monitoring"
    annotations = {
      "alb.ingress.kubernetes.io/scheme" =  "internet-facing"
      "alb.ingress.kubernetes.io/target-type" =  "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      host = "grafana.${var.DOMAIN}"
      http {
        path {
          path_type = "Prefix"
          path = "/"
          backend {
            service{
  	      name = "service-grafana"
              port {
                number = 3000
              }
            }
          }

        }

      }
    }
  }
}

#CRUD 이미지 빌드하기
resource "null_resource" "build_image" {
  depends_on = [terraform_data.update-output_json] #output update하고 build해야 함
  provisioner "local-exec" {
    command = <<EOT
      docker build -t dminus251/test:latest ./yyk-server/
      docker push dminus251/test:latest
    EOT
  }
}



#Service for Grafana
resource "kubernetes_service_v1" "service-grafana" {
  count			= var.create_cluster ? 1 : 0
  depends_on = [module.eks-cluster, module.node_group, helm_release.grafana]
  metadata {
    name = "service-grafana"
    namespace = "monitoring"
  }
  spec {
    type = "NodePort"
    selector = {
      "app.kubernetes.io/name" =  "grafana"
    }
    port {
      port        = 3000
      target_port = 3000
      protocol = "TCP"
    }
  }
}
