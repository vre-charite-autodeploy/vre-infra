# resource "helm_release" "vault" {
#   name = "vault"

#   repository = "https://helm.releases.hashicorp.com"
#   chart      = "vault"
#   version    = var.vault_chart_version
#   namespace  = "vault"
#   timeout    = "300"
#   wait       = var.helm-wait

#   values = [file("../../helm/vault/${var.env}/values.yaml")]
# }

resource "kubernetes_deployment" "fake_vault" {
  depends_on = [
    kubernetes_manifest.cert_manager_vault_server_certificate
  ]

  metadata {
    name      = "fake-vault"
    namespace = "vault"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "fake-vault"
      }
    }

    template {
      metadata {
        labels = {
          app = "fake-vault"
        }
      }

      spec {
        container {
          name  = "fake-vault"
          image = "nginx:latest"
          port {
            container_port = 8080
          }
          port {
            container_port = 443
          }

          volume_mount {
            name       = "nginx-config-volume"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }
          volume_mount {
            name       = "app-config-volume"
            mount_path = "/www/data/seed.json"
            sub_path   = "seed.json"
          }

          volume_mount {
            name       = "nginx-tls-volume"
            mount_path = "/etc/nginx/ssl"
            read_only  = true
          }
        }
        volume {
          name = "nginx-config-volume"

          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
          }
        }
        volume {
          name = "app-config-volume"

          config_map {
            name = kubernetes_config_map.app_config.metadata[0].name
          }
        }

        volume {
          name = "nginx-tls-volume"

          secret {
            secret_name = var.vault-server-certificate-name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "fake-vault" {
  metadata {
    name      = "vault"
    namespace = "vault"
  }

  spec {
    selector = {
      app = kubernetes_deployment.fake_vault.spec[0].template[0].metadata[0].labels["app"]
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
    port {
      name        = "https"
      port        = 443
      target_port = 443
    }

    port {
      name        = "vault-https"
      port        = 8200
      target_port = 443
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name      = "nginx-config"
    namespace = "vault"
  }

  data = {
    "nginx.conf" = file("../config/vault/nginx.conf")
  }
}

resource "kubernetes_config_map" "app_config" {
  depends_on = [
    random_password.minio_tenant_root_password,
    module.ingress_data.domain_name
  ]

  metadata {
    name      = "app-config"
    namespace = "vault"
  }
  ### endpoints presents in the seed.json
  # "DOMAIN_NAME": "https://vre.charite.de",
  # "INVITATION_URL_LOGIN": "https://vre.charite.de/vre/",
  # "KEYCLOAK_ENDPOINT": "http://10.32.42.226/vre/auth/realms/vre/protocol/openid-connect/token",
  # "PASSWORD_RESET_URL_PREFIX": "https://vre.charite.de",
  # "SITE_DOMAIN": "https://vre.charite.de",
  data = {
    "seed.json" = jsonencode({ data : merge(jsondecode(file("../config/vault/seed.json")), {
      MINIO_ENDPOINT             = "minio-hl.minio:9000",
      MINIO_SECRET_KEY           = local.minio_tenant_root_password,
      MINIO_ACCESS_KEY           = local.minio_tenant_root_user,
      DOMAIN_NAME                = module.ingress_data.domain_name_https
      SITE_DOMAIN                = module.ingress_data.domain_name_https,
      PASSWORD_RESET_URL_PREFIX  = module.ingress_data.domain_name_https,
      INVITATION_URL_LOGIN       = "${module.ingress_data.domain_name_https}/vre/",
      KEYCLOAK_ENDPOINT          = "${module.ingress_data.domain_name_https}/vre/auth/realms/vre/protocol/openid-connect/token",
      LDAP_ADMIN_PASSWORD        = random_password.openldap_passwords["admin"].result
      LDAP_CONFIG_ADMIN_PASSWORD = random_password.openldap_passwords["config"].result

      REDIS_PASSWORD = random_password.redis.result

      NEO4J_USER = var.neo4j_admin_username,
      NEO4J_PASS = random_password.neo4j.result,

      # service_queue/consumer environment
      gm_queue_endpoint = "rabbitmq-messagebus.greenroom"
      gm_username       = local.rabbitmq_username
      gm_password       = local.rabbitmq_password

      # Namespace here does not matter as username/password are the same in every namespace's secret
      RDS_USER   = kubernetes_secret.opsdb_indoc_vre[local.opsdb_namespace].data.username
      RDS_PWD    = kubernetes_secret.opsdb_indoc_vre[local.opsdb_namespace].data.password
      RDS_DB_URI = local.postgres_db_uri

      ATLAS_ADMIN  = local.atlas_admin_user
      ATLAS_PASSWD = random_password.atlas_admin_password.result

      KEYCLOAK_SECRET = random_password.kong_client_secret.result
    }) })
  }
}

resource "kubernetes_manifest" "cert_manager_vault_server_certificate" {
  manifest = yamldecode(<<EOT
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: vault-server-certificate
      namespace: vault
    spec:
      secretName: ${var.vault-server-certificate-name}

      commonName: vault
      dnsNames:
        - vault
        - vault.vault
        - vault.vault.svc
        - vault.vault.svc.cluster.local
        - fake-vault
        - fake-vault.vault
        - fake-vault.vault.svc
        - fake-vault.vault.svc.cluster.local
      usages:
        - server auth
      isCA: false

      duration: 2160h # 90d
      renewBefore: 360h # 15d

      subject:
        countries:
          - "DE"
        localities:
          - "Berlin"
        organizations:
          - "Charité Universitätsmedizin Berlin"
        organizationalUnits:
          - "VRE - Vault"

      privateKey:
        algorithm: ECDSA
        size: 256

      issuerRef:
        name: vre-pki-cluster-issuer
        kind: ClusterIssuer
        group: cert-manager.io
  EOT
  )
}
