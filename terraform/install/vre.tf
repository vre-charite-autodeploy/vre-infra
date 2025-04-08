resource "helm_release" "download_vre" {
  name = "download-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "download-service"
  version    = var.download_chart_version
  namespace  = "vre"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_download/${var.env}/vre/values.yaml")]

  set {
    name  = "image.tag"
    value = var.download_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_download"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "vre"
  }
}
resource "helm_release" "upload_vre" {
  name = "upload-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "upload-service"
  version    = var.upload_chart_version
  namespace  = "vre"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_upload/${var.env}/vre/values.yaml")]

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
    value = "vre"
  }
}

resource "kubernetes_manifest" "cert_manager_trust_manager_vre_operator_bundle" {
  manifest = yamldecode(<<EOT
    apiVersion: trust.cert-manager.io/v1alpha1
    kind: Bundle
    metadata:
      name: vre-root-certificate-bundle-vre
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
        # Sync the bundle to a ConfigMap called `vre-root-certificate-bundle-vre` in every namespace which
        # has the label "kubernetes.io/metadata.name: utility"
        configMap:
          key: "ca.crt"
        namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: vre
  EOT
  )
}
