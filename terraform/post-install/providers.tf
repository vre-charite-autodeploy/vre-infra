terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }

    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }

  backend "kubernetes" {
    secret_suffix = "post-install"
  }
}

data "kubernetes_secret" "keycloak_admin" {
  metadata {
    name      = "keycloak-admin"
    namespace = "utility"
  }
}

module "ingress_data" {
  source = "../modules/data-ingress"
}

provider "keycloak" {
  client_id                = "admin-cli"
  username                 = data.kubernetes_secret.keycloak_admin.data["username"]
  password                 = data.kubernetes_secret.keycloak_admin.data["password"]
  initial_login            = var.keycloak_initial_login
  url                      = module.ingress_data.domain_name_https
  base_path                = "/vre/auth"
  client_timeout           = 30
  tls_insecure_skip_verify = true
}
