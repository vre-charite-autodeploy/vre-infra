resource "kubernetes_secret" "download_greenroom_minio_app_secrets" {
  metadata {
    name      = "download-greenroom-minio-app-secrets"
    namespace = "greenroom"
  }

  data = {
    access-key : random_password.minio_indoc_user_access_key.result
    secret-key : random_password.minio_indoc_user_secret_key.result
  }
}

resource "helm_release" "download_greenroom" {
  depends_on = [
    kubernetes_secret.minio_credentials_for_distribution,
    kubernetes_secret.minio_keycloak_client,
    kubernetes_secret.download_greenroom_minio_app_secrets,
    kubernetes_secret.opsdb_indoc_vre,
    kubernetes_secret.redis-password,
    kubernetes_manifest.cert_manager_trust_manager_greenroom_operator_bundle
  ]

  name = "download-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "download-service"
  version    = var.download_chart_version
  namespace  = "greenroom"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_download/${var.env}/greenroom/values.yaml")]
}

locals {
  pipelinewatch_service_account_role_yamls = [for doc in split("---", file("${path.module}/manifests/pipeline_watch_sa.yaml")) : yamldecode(doc)]
}

# This could also be integrated with the helm chart for pipelinewatch
resource "kubernetes_manifest" "pipelinewatch_service_account_role" {

  depends_on = [helm_release.pipelinewatch]
  count      = length(local.pipelinewatch_service_account_role_yamls)
  manifest   = local.pipelinewatch_service_account_role_yamls[count.index]
}

resource "helm_release" "pipelinewatch" {
  name = "pipelinewatch-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "pipelinewatch-service"
  version    = var.pipelinewatch_chart_version
  namespace  = "greenroom"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_pipelinewatch/${var.env}/values.yaml")]
}

resource "helm_release" "upload_greenroom" {
  name = "upload-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "upload-service"
  version    = var.upload_chart_version
  namespace  = "greenroom"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_upload/${var.env}/greenroom/values.yaml")]

  set {
    name  = "image.tag"
    value = var.upload_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_upload"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "greenroom"
  }
}

resource "helm_release" "queue-consumer" {
  name = "queue-consumer-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "queue-service"
  version    = var.queue-consumer_chart_version
  namespace  = "greenroom"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_queue/consumer/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.queue-consumer_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_queue/consumer"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "greenroom"
  }
}

resource "helm_release" "queue-producer" {
  name = "queue-producer-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "queue-service"
  version    = var.queue-producer_chart_version
  namespace  = "greenroom"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_queue/producer/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.queue-producer_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_queue/producer"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "greenroom"
  }
}

resource "helm_release" "queue-socketio" {
  name = "queue-socketio-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "queue-service"
  version    = var.queue-socketio_chart_version
  namespace  = "greenroom"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_queue/socketio/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.queue-socketio_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_queue/socketio"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "greenroom"
  }
}

locals {
  rabbitmq_username = var.rabbitmq_username
  rabbitmq_password = var.rabbitmq_password
}

resource "kubernetes_secret" "rabbitmq_credentials" {
  metadata {
    name      = "rabbitmq-credentials"
    namespace = "greenroom"
  }

  data = {
    username = local.rabbitmq_username
    password = local.rabbitmq_password
  }

  type = "Opaque"
}

locals {
  rabbitmq_manifests = [for doc in split("---", file("${path.module}/manifests/rabbitmq-messagebus.yaml")) : yamldecode(doc)]
}

# This could also be integrated with the helm chart for pipelinewatch
resource "kubernetes_manifest" "rabbitmq_manifests" {
  depends_on = [helm_release.pipelinewatch]
  count      = length(local.rabbitmq_manifests)
  manifest   = local.rabbitmq_manifests[count.index]
}

resource "kubernetes_manifest" "cert_manager_trust_manager_greenroom_operator_bundle" {
  manifest = yamldecode(<<EOT
    apiVersion: trust.cert-manager.io/v1alpha1
    kind: Bundle
    metadata:
      name: vre-root-certificate-bundle-greenroom
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
        # Sync the bundle to a ConfigMap called `vre-root-certificate-bundle-greenroom` in every namespace which
        # has the label "kubernetes.io/metadata.name: utility"
        configMap:
          key: "ca.crt"
        namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: greenroom
  EOT
  )
}
