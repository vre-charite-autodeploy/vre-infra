locals {
  kong_namespace = "utility"
}

resource "helm_release" "kong" {
  name = "kong"

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "kong"
  version    = var.kong_chart_version
  namespace  = local.kong_namespace

  timeout = "900"
  wait    = var.helm-wait

  # cf. https://github.com/bitnami/charts/blob/main/bitnami/kong/values.yaml
  values = [file("./helm/kong/${var.env}/values.yaml")]
}


resource "random_password" "kong_client_secret" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "kong_keycloak_client" {
  metadata {
    name      = "kong-keycloak-client"
    namespace = local.kong_namespace
  }

  data = {
    client-id = var.kong_keycloak_client_id
    secret    = random_password.kong_client_secret.result
  }
}
