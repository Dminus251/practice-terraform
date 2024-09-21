#Ingress for Prometheus
resource "kubernetes_ingress_v1" "ingress-prometheus" { 
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

#Service for Grafana
resource "kubernetes_service_v1" "service-grafana" {
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
