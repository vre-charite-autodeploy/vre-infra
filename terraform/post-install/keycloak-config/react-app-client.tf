resource "keycloak_openid_client" "react_app_client" {
  realm_id                     = keycloak_realm.vre.id
  client_id                    = "react-app"
  enabled                      = true
  access_type                  = "PUBLIC"
  valid_redirect_uris          = var.react_app_valid_redirect_uris
  web_origins                  = var.react_app_web_origins
  standard_flow_enabled        = true
  direct_access_grants_enabled = true

}

#--------------------------------
# set scopes for react-app client
#--------------------------------

resource "keycloak_openid_client_default_scopes" "react_app_client_scope" {
  realm_id  = keycloak_realm.vre.id
  client_id = keycloak_openid_client.react_app_client.id
  default_scopes = [
    keycloak_openid_client_scope.openid_client_scope.name,
    "email",
    "profile",
    "roles"
  ]
}

#------------------------------------
# create mappers for react-app client
#------------------------------------

resource "keycloak_openid_user_session_note_protocol_mapper" "react_app_client_ip_address" {
  name                = "Client IP Address"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.react_app_client.id
  claim_name          = "clientAddress"
  session_note        = "clientAddress"
  add_to_id_token     = true
  add_to_access_token = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "react_app_client_group" {
  name                = "Client Group"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.react_app_client.id
  claim_name          = "groups"
  full_path           = true
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

resource "keycloak_openid_user_session_note_protocol_mapper" "react_app_client_id" {
  name                = "Client ID"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.react_app_client.id
  claim_name          = "clientId"
  session_note        = "clientId"
  add_to_id_token     = true
  add_to_access_token = true
}

resource "keycloak_openid_user_attribute_protocol_mapper" "minio_policy_mapper" {
  name                = "minio_policy_mapper"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.react_app_client.id
  user_attribute      = "policy"
  claim_name          = "policy"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
  multivalued         = false
}

resource "keycloak_openid_user_session_note_protocol_mapper" "react_app_client_host" {
  name                = "Client Host"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.react_app_client.id
  claim_name          = "clientHost"
  session_note        = "clientHost"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
}
