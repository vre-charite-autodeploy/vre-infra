#-------------------------
# admin user configuration
#-------------------------

variable "keycloak_realm" {
  type = string
}

variable "vre_admin_username" {
  default = "admin"
}

variable "vre_admin_password" {
  default = "$PASSWORD"
}

variable "vre_admin_email" {
  default = "vre-admin@charite.de"
}

#-------------------------------
# react-app client configuration
#-------------------------------

variable "react_app_valid_redirect_uris" {
  type    = list(string)
  default = ["*"]
}

variable "react_app_web_origins" {
  type    = list(string)
  default = ["*"]
}

#--------------------------
# kong client configuration
#--------------------------

variable "kong_valid_redirect_uris" {
  type    = list(string)
  default = ["*"]
}

variable "kong_root_url" {
  type    = string
  default = "http://kong.utility:8000" # default value, can be overridden in another build step
}

variable "kong_client_secret" {
  type      = string
  sensitive = true
}

variable "create_kong_client_default_mappers" {
  type        = bool
  default     = false
  description = "If Client ID, Client Host and Client IP Adress mappers are not created automatically anymore for service account enabled clients."
}

#---------------------------
# minio client configuration
#---------------------------

variable "minio_client_id" {
  type        = string
  description = "The client id used for the minio client in keyclaok."
}

variable "minio_client_secret" {
  type        = string
  sensitive   = true
  description = "The secret key the minio client is created with in Keycloak."
}

variable "minio_valid_redirect_uris" {
  type    = list(string)
  default = ["*"]
}

variable "minio_policy_script_mapper" {
  default = <<EOL
/**
 * Available variables:
 * user - the current user
 * realm - the current realm
 * token - the current token
 * userSession - the current userSession
 * keycloakSession - the current keycloakSession
 */

var ArrayList = Java.type("java.util.ArrayList");
var roles = new ArrayList();

// Retrieve realm role mappings and add them to the policy
var rr = user.getRealmRoleMappings();
for each (var r in rr) {
    var role_name = r.getName();
    if (role_name == "platform-admin") {
        roles.add("readwrite");
    } else {
        roles.add(role_name);
    }
}

// Assign read/write access to the "admin" user
if (user.getUsername() == "admin") {
    roles.add("readwrite");
}

// Add the username as a policy claim
roles.add(user.getUsername());

// Set the policy claim in the token
token.setOtherClaims("policy", roles);
EOL
}

#-----------------------
# openldap configuration
#-----------------------

variable "openldap_admin_password" {
  type      = string
  sensitive = true
}

variable "openldap_namespace" {
  type = string
}
