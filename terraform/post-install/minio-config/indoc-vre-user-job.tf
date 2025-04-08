resource "kubernetes_job" "indoc_vre_user_job" {
  depends_on = [
    kubernetes_secret.indoc_vre_user_configuration_secret
  ]

  metadata {
    name      = "indoc-vre-user-job"
    namespace = var.minio_configuration_namespace
  }

  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "indoc-vre-user-job"
          image   = "minio/mc:latest"
          command = ["sh", "-c"]
          args    = ["mc alias set $MINIO_ALIAS ${var.minio_tenant_url} $ROOT_ACCESS_KEY $ROOT_SECRET_KEY && mc admin user add $MINIO_ALIAS $ACCESS_KEY $SECRET_KEY && mc admin policy attach $MINIO_ALIAS readwrite --user $ACCESS_KEY"]
          volume_mount {
            mount_path = "/etc/vre/pki"
            name       = "vre-pki-root"
          }
          env {
            name  = "SSL_CERT_FILE"
            value = "/etc/vre/pki/ca.crt"
          }
          env {
            name  = "MINIO_ALIAS"
            value = "myminio"
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.indoc_vre_user_configuration_secret.metadata[0].name
            }
          }
        }
        volume {
          name = "vre-pki-root"
          config_map {
            name = var.root_pki_ca_bundle
            items {
              key  = "ca.crt"
              path = "ca.crt"
            }
          }
        }
        restart_policy = "Never"
      }
    }
  }
}

resource "kubernetes_secret" "indoc_vre_user_configuration_secret" {
  metadata {
    name      = "indoc-vre-user-configuration-secret"
    namespace = var.minio_configuration_namespace
  }

  data = {
    ACCESS_KEY : var.minio_vre_user_access_key
    SECRET_KEY : var.minio_vre_user_secret_key
    ROOT_ACCESS_KEY : var.minio_root_user_access_key
    ROOT_SECRET_KEY : var.minio_root_user_secret_key
  }
}
