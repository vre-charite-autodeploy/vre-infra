resource "helm_release" "jaeger_operator" {
  name = "jaeger"

  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger-operator"

  namespace = "observability"
  timeout   = "300"

  values = [file("./helm/jaeger/${var.env}/values.yaml")]
}
