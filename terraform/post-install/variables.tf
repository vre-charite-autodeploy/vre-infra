variable "keycloak_initial_login" {
  type        = bool
  description = "Should user have to set a new password on first login"
  default     = false
}

variable "keycloak_realm" {
  type = string
}

variable "openldap_namespace" {
  type = string
}
