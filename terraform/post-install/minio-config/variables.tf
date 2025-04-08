variable "minio_configuration_namespace" {
  type        = string
  description = "Namespace in which the configuration job(s) will run."
}

variable "minio_tenant_url" {
  type        = string
  description = "The URL to of the tenant to configure. In the format <schema>://<domain>:<port>"
}

variable "minio_root_user_access_key" {
  type        = string
  description = "The access key of the minio root user (is the username as well)."
}

variable "minio_root_user_secret_key" {
  type        = string
  sensitive   = true
  description = "The secret key of the minio root user."
}

variable "minio_vre_user_access_key" {
  type        = string
  description = "The access key of the VRE user (is the username as well)."
}

variable "minio_vre_user_secret_key" {
  type        = string
  sensitive   = true
  description = "The secret key of the VRE user."
}

variable "root_pki_ca_bundle" {
  type        = string
  description = "Name of the config map containing the vre root pki. The bundle must exist in the `minio_configuration_namespace`."
}
