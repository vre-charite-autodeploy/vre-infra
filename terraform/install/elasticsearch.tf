resource "helm_release" "elasticsearch" {
  name = "elasticsearch"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "elasticsearch-7.8.1"
  version    = "7.8.1"
  namespace  = "utility"

  values = [file("./helm/elasticsearch/${var.env}/values.yaml")]

  # Timeout for any kubernetes operation. As a rolling update of a stateful set is considered
  # one kubernetes operation, we have to wait until all replicas (three) of the stateful set have restarted.
  # In seconds, 20 minute timeout.
  timeout = 1200
}
