data "kubernetes_service" "ingress" {
  metadata {
    name      = "nginx-ingress-controller"
    namespace = "ingress"
  }

  lifecycle {
    postcondition {
      condition     = length(flatten(self.status[*].load_balancer[*].ingress[*].ip)) == 1
      error_message = "Found more then 1 loadbalancer IP(s)"
    }
  }
}

locals {
  load_balancer_ip = data.kubernetes_service.ingress.status[0].load_balancer[0].ingress[0].ip
}