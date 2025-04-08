resource "helm_release" "openldap" {
  depends_on = [
    kubernetes_secret.openldap_admin_credentials["utility"],
    kubernetes_manifest.openldap_certificate
  ]
  name = "openldap"

  repository = "https://jp-gouin.github.io/helm-openldap/"
  chart      = "openldap-stack-ha"
  version    = var.openldap_chart_version
  namespace  = "utility"

  timeout = "900"
  wait    = var.helm-wait

  values = [file("../../helm/openldap/${var.env}/values.yaml")]
}

resource "kubernetes_secret" "openldap_admin_credentials" {
  for_each = toset(["utility"])
  metadata {
    name      = "openldap-admin-credentials"
    namespace = each.value
    annotations = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    LDAP_ADMIN_PASSWORD        = random_password.openldap_passwords["admin"].result
    LDAP_CONFIG_ADMIN_PASSWORD = random_password.openldap_passwords["config"].result
  }

  type = "Opaque"
}

resource "random_password" "openldap_passwords" {
  for_each = {
    admin  = "openldap_admin_password"
    config = "openldap_config_password"
  }

  length  = 16
  special = false
}

resource "kubernetes_manifest" "openldap_certificate" {
  manifest = yamldecode(<<EOT
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: openldap
      namespace: utility
    spec:
      commonName: openldap
      dnsNames:
        - "openldap"
        - "openldap.utility"
        - "openldap.utility.svc"
        - "openldap.utility.svc.cluster.local"
        - "*.openldap-headless.openldap.svc.cluster.local"
      secretName: openldap
      issuerRef:
        name: vre-pki-cluster-issuer
        kind: ClusterIssuer
        group: cert-manager.io
  EOT
  )
}
