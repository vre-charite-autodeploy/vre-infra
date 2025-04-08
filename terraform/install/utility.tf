resource "helm_release" "kg" {
  name = "kg-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "kg-service"
  version    = var.kg_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_kg/charite/values.yaml")]

  set {
    name  = "image.tag"
    value = var.kg_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_kg"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

resource "helm_release" "entityinfo" {
  name = "entityinfo-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "entityinfo-service"
  version    = var.entityinfo_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_entityinfo/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.entityinfo_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_entityinfo"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

resource "helm_release" "approval" {
  name = "approval-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "approval-service"
  version    = var.approval_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_approval/${var.env}/values.yaml")]

  set {
    name  = "extraEnv.RDS_SCHEMA_DEFAULT"
    value = local.indoc_vre_db
  }
}

resource "helm_release" "service_common" {
  name       = "common"
  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "common-service"
  version    = var.service_common_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("./helm/service_common/${var.env}/values.yaml")]
}

resource "helm_release" "auth" {
  depends_on = [
    kubernetes_manifest.cert_manager_trust_manager_utility_operator_bundle
  ]
  name = "auth-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "auth-service"
  version    = var.auth_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_auth/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.auth_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_auth"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }

  set {
    name  = "appConfig.KEYCLOAK_CLIENT_ID"
    value = var.kong_keycloak_client_id
  }

  set {
    name  = "appConfig.KEYCLOAK_REALM"
    value = var.keycloak_realm
  }

  set {
    name  = "appConfig.DOMAIN_NAME"
    value = module.ingress_data.domain_name_https
  }

  set {
    name  = "appConfig.LDAP_COMMON_NAME_PREFIX"
    value = var.keycloak_realm
  }
}

resource "helm_release" "bff" {
  depends_on = [
    kubernetes_secret.minio_credentials_for_distribution
  ]

  name = "bff-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "bff"
  version    = var.bff_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/bff/${var.env}/values.yaml")]
}

resource "helm_release" "bff-vrecli" {
  name = "bff-vrecli-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "bff-cli-service"
  version    = var.bff-vrecli_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/bff-vrecli/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.bff-vrecli_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/bff_vrecli"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

resource "helm_release" "cataloguing" {
  name = "cataloguing-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "cataloguing-service"
  version    = var.cataloguing_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_cataloguing/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.cataloguing_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_cataloguing"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

resource "helm_release" "dataops-utility" {
  name = "dataops-utility-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "dataops-utility-service"
  version    = var.dataops-utility_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_dataops_utility/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.dataops-utility_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_dataops_utility"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

resource "helm_release" "dataset-neo4j" {
  name = "dataset-neo4j-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "dataset-neo4j"
  version    = var.dataset-neo4j_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/dataset_neo4j/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.dataset-neo4j_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_neo4j"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

resource "helm_release" "notification" {
  depends_on = [
    kubernetes_secret.opsdb_indoc_vre,
  ]

  name = "notification-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "notification-service"
  version    = var.notification_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_notification/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.notification_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_notification"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

locals {
  notification_db_dumps_manifests = [for doc in split("---", file("${path.module}/manifests/notification_db_dump.yaml")) : yamldecode(doc)]
}

# This could also be integrated with the helm chart for pipelinewatch
resource "kubernetes_manifest" "notification_db_dumps_manifests" {
  depends_on = [helm_release.pipelinewatch]
  count      = length(local.notification_db_dumps_manifests)
  manifest   = local.notification_db_dumps_manifests[count.index]
}

resource "helm_release" "provenance" {
  name = "provenance-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "provenance-service"
  version    = var.provenance_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_provenance/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.provenance_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_provenance"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

resource "helm_release" "dataset" {
  name = "dataset-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "dataset-service"
  version    = var.dataset_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/service_dataset/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.dataset_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_dataset"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
  set_list {
    name  = "command"
    value = ["sh"]
  }

  set_list {
    name = "args"
    value = [
      "-c",
      "mc alias set minio https://minio-hl.minio:9000 ${local.minio_tenant_root_user} ${local.minio_tenant_root_password} --insecure --api s3v4 && ./gunicorn_starter.sh"
    ]
  }
}

resource "helm_release" "encryption" {
  name = "encryption-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "encryption-service"
  version    = var.encryption_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify


  values = [file("../../helm/service_encryption/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = var.encryption_app_version
  }
  set {
    name  = "image.repository"
    value = "${var.repository}/service_encryption"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

resource "helm_release" "portal" {
  name = "portal-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "portal"
  version    = var.portal_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/portal/${var.env}/values.yaml")]

  set {
    name  = "image.tag"
    value = "168-add-copyright-notice-2a530ee"
  }
  set {
    name  = "image.repository"
    value = "ghcr.io/vre-charite-autodeploy/core/portal"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "imagePullSecrets[0].namespace"
    value = "utility"
  }
}

resource "kubernetes_manifest" "frontend_vre_home_resources" {
  manifest = yamldecode(<<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: vre-ingress
      namespace: utility
      annotations:
        nginx.org/path-regex: "case_insensitive"
        nginx.ingress.kubernetes.io/x-forwarded-for: "true"
        nginx.ingress.kubernetes.io/x-forwarded-proto: "http"
        nginx.ingress.kubernetes.io/rewrite-target: /$1
        nginx.ingress.kubernetes.io/proxy-body-size: "20m" # Allow large requests if necessary
        nginx.ingress.kubernetes.io/proxy-buffering: "on"
        nginx.ingress.kubernetes.io/proxy-buffer-size: "512k" # Buffer size to handle larger headers if needed
        nginx.ingress.kubernetes.io/proxy-buffers-number: "8"
        nginx.ingress.kubernetes.io/proxy-max-temp-file-size: "0"
        nginx.ingress.kubernetes.io/proxy-connect-timeout: "180s"
        nginx.ingress.kubernetes.io/proxy-read-timeout: "180s"
        nginx.ingress.kubernetes.io/proxy-send-timeout: "180s"
        cert-manager.io/cluster-issuer: vre-pki-cluster-issuer
    spec:
      ingressClassName: nginx
      tls:
        - hosts:
            - ${module.ingress_data.domain_name}
          secretName: ingress-certificate
      rules:
      - host: ${module.ingress_data.domain_name}
        http:
          paths:
            - path: /(vre/auth/.*)
              pathType: ImplementationSpecific
              backend:
                service:
                  name: keycloak
                  port:
                    number: 80
            - path: /vre/(pages/.*)
              pathType: ImplementationSpecific
              backend:
                service:
                  name: vre-home
                  port:
                    number: 80
            - path: /vre/(api/vre.*)
              pathType: ImplementationSpecific
              backend:
                service:
                  name: kong
                  port:
                    number: 80
            - path: /vre/(_next/.*)
              pathType: ImplementationSpecific
              backend:
                service:
                  name: vre-home
                  port:
                    number: 80
            - path: /(vre/.+)
              pathType: ImplementationSpecific
              backend:
                service:
                  name: portal
                  port:
                    number: 80
            - path: /vre($|/$)
              pathType: ImplementationSpecific
              backend:
                service:
                  name: vre-home
                  port:
                    number: 80
  EOF
  )

}

resource "kubernetes_manifest" "cert_manager_trust_manager_utility_operator_bundle" {
  manifest = yamldecode(<<EOT
    apiVersion: trust.cert-manager.io/v1alpha1
    kind: Bundle
    metadata:
      name: vre-root-certificate-bundle-utility
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
        # Sync the bundle to a ConfigMap called `vre-root-certificate-bundle-utility` in every namespace which
        # has the label "kubernetes.io/metadata.name: utility"
        configMap:
          key: "ca.crt"
        namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: utility
  EOT
  )
}

# resource "helm_release" "maintenance-page" {
#   name = "maintenance-page-service"

#   repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
#   chart      = "maintenance-page"
#   version    = var.maintenance-page_chart_version
#   namespace  = "utility"
#   timeout    = "300"
#   wait       = var.helm-wait
#   verify     = var.helm-verify

#   values = [file("../../helm/maintenance-page/${var.env}/values.yaml")]

#   set {
#     name  = "image.tag"
#     value = var.maintenance-page_app_version
#   }
#   set {
#     name  = "image.repository"
#     value = "${var.repository}/core/maintenance-page"
#   }
#   set {
#     name  = "imagePullSecrets[0].name"
#     value = "regcred"
#   }
#   set {
#     name  = "imagePullSecrets[0].namespace"
#     value = "utility"
#   }
# }


resource "helm_release" "vre-home" {
  name = "vre-home-service"

  repository = "oci://ghcr.io/vre-charite-autodeploy/helm-charts"
  chart      = "vre-home-service"
  version    = var.frontend-vre-home_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("../../helm/frontend-vre-home/${var.env}/values.yaml")]
}

resource "helm_release" "mailhog" {
  name = "mailhog"

  repository = "oci://ghcr.io/codecentric/helm-charts"
  chart      = "mailhog"
  version    = "5.8.0"
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait
  verify     = var.helm-verify

  values = [file("./helm/mailhog/${var.env}/values.yaml")]
}
