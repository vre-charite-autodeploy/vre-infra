locals {
  tenant_release_name        = "minio-tenant"
  minio_tenant_root_user     = "minio_admin"
  minio_tenant_root_password = "adminadmin"
  minio_uri_endpoint         = "https://minio-hl.minio:9000"
}

resource "random_password" "minio_tenant_root_password" {
  length = 32
}

output "minio_tenant_root_password" {
  value     = local.minio_tenant_root_password
  sensitive = true
}

output "minio_tenant_root_user" {
  value = local.minio_tenant_root_user
}

resource "kubernetes_secret" "minio_env_configuration" {
  depends_on = [random_password.minio_tenant_root_password]
  for_each   = var.minio_tenant_namespaces

  metadata {
    name      = "minio-env-configuration"
    namespace = each.value

    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }

    annotations = {
      "meta.helm.sh/release-name"      = local.tenant_release_name,
      "meta.helm.sh/release-namespace" = each.value
    }
  }

  data = {
    "config.env" = <<EOT
export MINIO_ROOT_USER=${local.minio_tenant_root_user}
export MINIO_ROOT_PASSWORD=${local.minio_tenant_root_password}
export MINIO_NOTIFY_AMQP_ENABLE_GREENROOM="on"
export MINIO_NOTIFY_AMQP_URL_GREENROOM="amqp://${local.rabbitmq_username}:${local.rabbitmq_password}@message-bus-greenroom.greenroom:5672"
export MINIO_NOTIFY_AMQP_EXCHANGE_GREENROOM="direct_logs"
export MINIO_NOTIFY_AMQP_EXCHANGE_TYPE_GREENROOM="direct"
export MINIO_NOTIFY_AMQP_ROUTING_KEY_GREENROOM="indoc"
    EOT
  }

  type = "Opaque"
}

resource "kubernetes_secret" "minio_credentials_for_distribution" {

  for_each = toset(["utility", "greenroom"])
  metadata {
    name      = "minio-tenant-credentials"
    namespace = each.value
    annotations = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    MINIO_URI_ENDPOINT     = local.minio_uri_endpoint
    MINIO_TENANT_ROOT_USER = local.minio_tenant_root_user
    MINIO_TENANT_ROOT_PASS = local.minio_tenant_root_password
  }

  type = "Opaque"
}

resource "kubernetes_storage_class" "retain_policy_storage_class" {
  storage_provisioner    = "cinder.csi.openstack.org"
  reclaim_policy         = "Retain"
  allow_volume_expansion = true

  metadata {
    name = "minio-storage"
  }
}

resource "helm_release" "minio_operator" {
  name       = "minio-operator"
  chart      = "operator"
  repository = "https://operator.min.io"
  version    = var.minio_chart_version

  namespace = var.minio_operator_namespace

  # cf. https://github.com/minio/operator/blob/v6.0.4/helm/operator/values.yaml
  values = [file("../../helm/minio/operator/${var.env}/values.yaml")]
}

resource "helm_release" "minio_tenant" {
  for_each   = var.minio_tenant_namespaces
  name       = local.tenant_release_name
  chart      = "tenant"
  repository = "https://operator.min.io"
  version    = var.minio_chart_version

  namespace = each.value

  # cf. https://github.com/minio/operator/blob/v6.0.4/helm/tenant/values.yaml
  values = [file("../../helm/minio/tenant/${var.env}/values.yaml")]

  depends_on = [
    helm_release.minio_operator,
    kubernetes_storage_class.retain_policy_storage_class,
    kubernetes_secret.minio_env_configuration
  ]
}

resource "kubernetes_manifest" "cert_manager_trust_manager_minio_operator_bundle" {
  manifest = yamldecode(<<EOT
    apiVersion: trust.cert-manager.io/v1alpha1
    kind: Bundle
    metadata:
      name: operator-ca-tls-${local.tenant_release_name}
    spec:
      sources:
        # We want to distribute our root certificate as trust anchor.
        # As this does not have an issuing certificate, we rather use the public part of the certificate instead of the
        # `ca.crt` key even though they ought to be the same, in order to ensure to really always distribute the correct
        # certificate to the targets.
        - secret:
            name: "vre-root-certificate"
            key: "tls.crt"

      target:
        # Sync the bundle to a Secret called `operator-ca-tls-${local.tenant_release_name}` in every namespace which
        # has the label "kubernetes.io/metadata.name: ${var.minio_operator_namespace}".
        secret:
          key: "ca.crt"
        namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: ${var.minio_operator_namespace}
  EOT
  )
}

resource "random_password" "minio_keycloak_client_secret" {
  length = 32
}

resource "kubernetes_secret" "minio_keycloak_client" {
  for_each = toset(["greenroom"])
  metadata {
    name      = "minio-keycloak-client"
    namespace = each.value
  }

  data = {
    client-id : var.minio_keycloak_client_id
    secret : random_password.minio_keycloak_client_secret.result
  }
}

#-------------------------------------
# Indoc User API Key creation
# User creation itself in post-install
#-------------------------------------

resource "random_password" "minio_indoc_user_access_key" {
  length  = 32
  special = false
  numeric = false
}

resource "random_password" "minio_indoc_user_secret_key" {
  length  = 32
  special = false
  numeric = false
}
