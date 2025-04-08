resource "keycloak_ldap_user_federation" "ldap_user_federation" {
  realm_id = keycloak_realm.vre.id
  name     = "ldap"

  # LDAP connection settings
  connection_url  = "ldap://openldap.${var.openldap_namespace}:389"
  users_dn        = "ou=Users,dc=charite,dc=de"
  bind_dn         = "cn=admin,dc=charite,dc=de"
  bind_credential = var.openldap_admin_password

  # LDAP synchronization settings
  import_enabled          = true
  edit_mode               = "WRITABLE"
  sync_registrations      = true
  vendor                  = "AD"
  username_ldap_attribute = "uid"
  rdn_ldap_attribute      = "cn"
  uuid_ldap_attribute     = "entryUUID"
  user_object_classes     = ["inetOrgPerson"]
  connection_timeout      = "5s"
  read_timeout            = "10s"
  pagination              = true

  # Advanced settings
  search_scope       = "ONE_LEVEL"
  trust_email        = true
  use_truststore_spi = "ONLY_FOR_LDAPS"
}

#------------------------
# create openldap mappers
#------------------------

# Create a group LDAP mapper
resource "keycloak_ldap_group_mapper" "group_mapper" {
  realm_id                       = keycloak_realm.vre.id
  ldap_user_federation_id        = keycloak_ldap_user_federation.ldap_user_federation.id
  name                           = "group_mapper"
  membership_user_ldap_attribute = ""
  # LDAP group settings
  ldap_groups_dn                       = "ou=Gruppen,ou=VRE,ou=Charite,dc=charite,dc=de" # Base DN for LDAP groups
  group_name_ldap_attribute            = "cn"                                            # LDAP attribute for group names
  group_object_classes                 = ["group"]                                       # Object class for LDAP groups
  membership_attribute_type            = "DN"                                            # Membership attribute type (DN or UID)
  membership_ldap_attribute            = "member"                                        # LDAP attribute for group membership
  memberof_ldap_attribute              = "memberOf"                                      # LDAP attribute for memberOf (optional)
  preserve_group_inheritance           = true                                            # Preserve group inheritance
  ignore_missing_groups                = false                                           # Ignore missing groups
  mapped_group_attributes              = ["description"]                                 # Additional group attributes to map
  drop_non_existing_groups_during_sync = false                                           # Drop non-existing groups during sync
}

#------------------------
# disable update password
#------------------------

resource "keycloak_required_action" "disable_update_password" {
  realm_id       = keycloak_realm.vre.id
  alias          = "UPDATE_PASSWORD"
  enabled        = false
  default_action = false
}
