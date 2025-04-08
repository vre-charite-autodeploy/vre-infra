output "atlas_admin_username" {
  description = "The username of the admin user of the Atlas service."
  value       = local.atlas_admin_user
}

output "atlas_admin_password" {
  description = "The admin password of the Atlas service."
  value       = random_password.atlas_admin_password.result
  sensitive   = true
}

output "kong_client_secret" {
  description = "The password of the Kong Client in Keycloak."
  value       = random_password.kong_client_secret.result
  sensitive   = true
}

output "openldap_admin_password" {
  description = "The password of the openldap admin user."
  value       = random_password.openldap_passwords["admin"].result
  sensitive   = true
}

output "openldap_config_password" {
  description = "The password of the openldap config user."
  value       = random_password.openldap_passwords["config"].result
  sensitive   = true
}

#-----------------
#      Minio
#-----------------
output "minio_client_id" {
  value       = var.minio_keycloak_client_id
  description = "The name of the Keycloak client used by minio. Matches to the keycloak client id."
}

output "minio_client_secret" {
  description = "The secret of the minio client in Keycloak."
  value       = random_password.minio_keycloak_client_secret.result
  sensitive   = true
}

output "minio_uri_endpoint" {
  description = "URI to reach the minio endpoint. In the format <scheme>://<domain>:<port>"
  value       = local.minio_uri_endpoint
}

output "minio_indoc_user_access_key" {
  description = "The access key of the VRE user (is the username as well)."
  value       = random_password.minio_indoc_user_access_key.result
  sensitive   = true
}

output "minio_indoc_user_secret_key" {
  description = "The secret key of the VRE user."
  value       = random_password.minio_indoc_user_secret_key.result
  sensitive   = true
}
