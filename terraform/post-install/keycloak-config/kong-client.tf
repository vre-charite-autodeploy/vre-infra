resource "keycloak_openid_client" "kong_client" {
  realm_id                     = keycloak_realm.vre.id
  client_id                    = "kong"
  access_type                  = "CONFIDENTIAL"
  client_secret                = var.kong_client_secret
  enabled                      = true
  standard_flow_enabled        = true
  implicit_flow_enabled        = false
  direct_access_grants_enabled = true
  service_accounts_enabled     = true
  authorization {
    policy_enforcement_mode = "ENFORCING"
  }
  valid_redirect_uris = var.kong_valid_redirect_uris
  root_url            = var.kong_root_url
}

#--------------------
# create kong mappers
#--------------------

resource "keycloak_openid_user_session_note_protocol_mapper" "kong_client_ip_address" {
  count = var.create_kong_client_default_mappers ? 1 : 0

  name                = "Client IP Address"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.kong_client.id
  claim_name          = "clientAddress"
  session_note        = "clientAddress"
  add_to_id_token     = true
  add_to_access_token = true
}

resource "keycloak_openid_user_session_note_protocol_mapper" "kong_client_host" {
  count = var.create_kong_client_default_mappers ? 1 : 0

  name                = "Client Host"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.kong_client.id
  claim_name          = "clientHost"
  session_note        = "clientHost"
  add_to_id_token     = true
  add_to_access_token = true
}

resource "keycloak_openid_user_session_note_protocol_mapper" "kong_client_id" {
  count = var.create_kong_client_default_mappers ? 1 : 0

  name                = "Client ID"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.kong_client.id
  claim_name          = "clientId"
  session_note        = "clientId"
  add_to_id_token     = true
  add_to_access_token = true
}

resource "keycloak_openid_user_property_protocol_mapper" "kong_client_username_mapper" {
  name                = "map_username_to_sub"
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.kong_client.id
  user_property       = "username"
  claim_name          = "sub"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

resource "keycloak_openid_script_protocol_mapper" "kong_client_minio_policy_script_mapper" {
  realm_id            = keycloak_realm.vre.id
  client_id           = keycloak_openid_client.kong_client.id
  name                = "minio_policy_script_mapper"
  claim_name          = "policy"
  claim_value_type    = "String"
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
  script              = var.minio_policy_script_mapper
}

#----------------------------------
# create kong service account roles
#----------------------------------

resource "keycloak_openid_client_service_account_realm_role" "kong_admin_role" {
  realm_id                = keycloak_realm.vre.id
  role                    = keycloak_role.admin_role.name
  service_account_user_id = keycloak_openid_client.kong_client.service_account_user_id
}

#------------------
# create admin role
#------------------

data "keycloak_role" "offline_access" {
  realm_id = keycloak_realm.vre.id
  name     = "offline_access"
}

data "keycloak_role" "uma_authorization" {
  realm_id = keycloak_realm.vre.id
  name     = "uma_authorization"
}

data "keycloak_openid_client" "realm_management" {
  realm_id  = keycloak_realm.vre.id
  client_id = "realm-management"
}

data "keycloak_role" "manage_realm" {
  realm_id  = keycloak_realm.vre.id
  name      = "manage-realm"
  client_id = data.keycloak_openid_client.realm_management.id
}

data "keycloak_role" "manage_users" {
  realm_id  = keycloak_realm.vre.id
  name      = "manage-users"
  client_id = data.keycloak_openid_client.realm_management.id
}

resource "keycloak_role" "admin_role" {
  realm_id = keycloak_realm.vre.id
  name     = "admin-role"
  composite_roles = [
    data.keycloak_role.offline_access.id,
    data.keycloak_role.uma_authorization.id,
    data.keycloak_role.manage_realm.id,
    data.keycloak_role.manage_users.id
  ]
}
