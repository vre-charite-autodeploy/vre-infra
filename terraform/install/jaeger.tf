resource "kubernetes_manifest" "jaeger-opentelemetry-simplest" {
  manifest = {
    "apiVersion" = "jaegertracing.io/v1"
    "kind"       = "Jaeger"
    "metadata" = {
      "name"      = "jaeger-opentelemetry-simplest"
      "namespace" = "observability"
    }
  }
}
