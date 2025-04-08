resource "helm_release" "ngnix-ingress" {
  name      = "nginx-ingress"
  chart     = "oci://ghcr.io/nginxinc/charts/nginx-ingress"
  version   = var.ngnix_ingress_controller_version
  namespace = "ingress"
  timeout   = "300"
  wait      = "true"
}
