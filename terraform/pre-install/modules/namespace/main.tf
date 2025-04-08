resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace_name
  }
}

# changed ghcr_token 20.03.2025
resource "kubernetes_secret" "regcred" {
  metadata {
    name      = "regcred"
    namespace = var.namespace_name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          "auth" = base64encode(var.ghcr_token)
        }
      }
    })
  }
  depends_on = [kubernetes_namespace.namespace]
}

resource "kubernetes_secret" "vault_token" {
  metadata {
    name      = "vault-secret"
    namespace = var.namespace_name
  }

  data = {
    "token" = var.vault_token
  }
  depends_on = [kubernetes_namespace.namespace]
}

output "secret" {
  value      = "${kubernetes_secret.regcred.id} - ${kubernetes_secret.vault_token.id}"
  depends_on = [kubernetes_secret.regcred, kubernetes_secret.vault_token]
}
