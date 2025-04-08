data "terraform_remote_state" "install" {
  backend = "kubernetes"

  config = {
    secret_suffix = "install"
  }
}

module "keycloak-config" {
  source = "./keycloak-config"

  keycloak_realm          = var.keycloak_realm
  openldap_admin_password = data.terraform_remote_state.install.outputs.openldap_admin_password
  openldap_namespace      = var.openldap_namespace
  kong_client_secret      = data.terraform_remote_state.install.outputs.kong_client_secret
  minio_client_id         = data.terraform_remote_state.install.outputs.minio_client_id
  minio_client_secret     = data.terraform_remote_state.install.outputs.minio_client_secret
}

module "atlas-config" {
  source = "./atlas-config"

  atlas_admin_username = data.terraform_remote_state.install.outputs.atlas_admin_username
  atlas_admin_password = data.terraform_remote_state.install.outputs.atlas_admin_password
}

resource "kubernetes_manifest" "kong_configmap" {
  manifest = yamldecode(file("./kong-config/kong-cm.yaml"))
}

resource "kubernetes_manifest" "kong_job" {
  manifest = yamldecode(file("./kong-config/kong-job.yaml"))
}

module "minio_config" {
  source = "./minio-config"

  minio_configuration_namespace = "utility"
  minio_root_user_access_key    = data.terraform_remote_state.install.outputs.minio_tenant_root_user
  minio_root_user_secret_key    = data.terraform_remote_state.install.outputs.minio_tenant_root_password
  minio_vre_user_access_key     = data.terraform_remote_state.install.outputs.minio_indoc_user_access_key
  minio_vre_user_secret_key     = data.terraform_remote_state.install.outputs.minio_indoc_user_secret_key
  minio_tenant_url              = data.terraform_remote_state.install.outputs.minio_uri_endpoint
  root_pki_ca_bundle            = "vre-root-certificate-bundle-utility"
}

resource "kubernetes_manifest" "elasticsearch_index_configmap" {
  manifest = yamldecode(file("./elasticsearch-config/elasticsearch-indexes-cm.yaml"))
}

resource "kubernetes_manifest" "elasticsearch-index-job" {
  manifest = yamldecode(file("./elasticsearch-config/elasticsearch-index-job.yaml"))
}
