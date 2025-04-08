#---------------------
# create the vre realm
#---------------------

resource "keycloak_realm" "vre" {
  realm   = var.keycloak_realm
  enabled = true
}

#------------------------------------------
# create the openid scope for the vre realm
#------------------------------------------

resource "keycloak_openid_client_scope" "openid_client_scope" {
  realm_id               = keycloak_realm.vre.id
  name                   = "openid"
  include_in_token_scope = true
  consent_screen_text    = ""
}

#----------------------
# create the admin user
#----------------------

resource "keycloak_user" "admin_user" {
  realm_id = keycloak_realm.vre.id
  username = var.vre_admin_username
  email    = var.vre_admin_email
  enabled  = true

  initial_password {
    value     = var.vre_admin_password
    temporary = false
  }
}

resource "keycloak_role" "platform_admin" {
  realm_id = keycloak_realm.vre.id
  name     = "platform-admin"
}

resource "keycloak_user_roles" "admin_user_roles" {
  realm_id = keycloak_realm.vre.id
  user_id  = keycloak_user.admin_user.id

  role_ids = [
    keycloak_role.platform_admin.id
  ]
}
