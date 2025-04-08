resource "helm_release" "redis" {
  depends_on = [
    kubernetes_secret.redis-password["utility"]
  ]

  name = "redis"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "redis-11.0.6"
  version    = "11.0.6"
  namespace  = "utility"

  values = [file("./helm/redis/${var.env}/values.yaml")]
}

resource "random_password" "redis" {
  length = 32
}

resource "kubernetes_secret" "redis-password" {
  for_each = toset(["utility", "greenroom", "vre"])
  metadata {
    name      = "redis"
    namespace = each.value
    annotations = {
      "app.kubernetes.io/managed-by" : "terraform"
    }
  }

  type = "Opaque"

  data = {
    redis-password = random_password.redis.result
  }
}
