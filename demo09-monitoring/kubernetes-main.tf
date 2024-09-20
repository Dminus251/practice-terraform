resource "kubernetes_ingress_v1" "ingress-prometheus" { 
  depends_on = [module.eks-cluster, module.node_group, helm_release.prometheus]
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
      host = "prometheus.youngkyu.me"
      http {
        path {
          path_type = "Prefix"
          path = "/"
          backend {
            service{
  	      name = "service-prometheus"
              port {
                number = 80
              }
            }
          }

        }

      }
    }
  }
}


resource "kubernetes_service_v1" "example" {
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
      port        = 80
      target_port = 9090
      protocol = "TCP"
    }
  }
}


