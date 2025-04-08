resource "keycloak_openid_client" "minio_client" {
  realm_id                     = keycloak_realm.vre.id
  client_id                    = var.minio_client_id
  access_type                  = "CONFIDENTIAL"
  client_secret                = var.minio_client_secret
  enabled                      = true
  standard_flow_enabled        = true
  implicit_flow_enabled        = true
  direct_access_grants_enabled = true
  valid_redirect_uris          = var.minio_valid_redirect_uris
}

#----------------------------------------------------
# add user attribute protocol mapper for minio client
#----------------------------------------------------

resource "keycloak_openid_user_attribute_protocol_mapper" "minio_client_policy_mapper" {
  name                = "minio_client_policy_mapper"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.minio_client.id
  user_attribute      = "policy"
  claim_name          = "policy"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
  multivalued         = false
}

#---------------------------------------------
# add script protocol mappers for minio client
#---------------------------------------------

resource "keycloak_openid_script_protocol_mapper" "minio_client_policy_script_mapper" {
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.minio_client.id
  name                = "minio_client_policy_script_mapper"
  claim_name          = "policy"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
  script              = var.minio_policy_script_mapper
}

resource "keycloak_openid_script_protocol_mapper" "minio_policy_script_mapper" {
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.react_app_client.id
  name                = "minio_policy_script_mapper"
  claim_name          = "policy"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
  script              = var.minio_policy_script_mapper
}
