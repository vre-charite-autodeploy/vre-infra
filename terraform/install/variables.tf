variable "env" {
  type    = string
  default = "charite"
}

variable "kubeconfig" {
  type        = string
  description = "Path to the kubeconfig file"
  default     = "~/.kube/config"
}

variable "helm-wait" {
  type        = bool
  description = "Will wait until all helm-release resources are in a ready state before marking the release as successful."
  default     = "false"
}

variable "helm-verify" {
  type    = bool
  default = "false"
}

variable "hpc_chart_version" {
  type = string
}

variable "hpc_app_version" {
  type = string
}

variable "kg_chart_version" {
  type = string
}

variable "kg_app_version" {
  type = string
}

variable "entityinfo_chart_version" {
  type = string
}

variable "entityinfo_app_version" {
  type = string
}

variable "approval_chart_version" {
  type = string
}

variable "approval_app_version" {
  type = string
}

variable "service_common_chart_version" {
  type = string
}

variable "auth_chart_version" {
  type = string
}

variable "auth_app_version" {
  type = string
}

variable "bff_chart_version" {
  type = string
}

variable "bff-vrecli_chart_version" {
  type = string
}

variable "bff-vrecli_app_version" {
  type = string
}

variable "cataloguing_chart_version" {
  type = string
}

variable "cataloguing_app_version" {
  type = string
}

#variable "common_chart_version" {
#  type = string
#}
#
#variable "common_app_version" {
#  type = string
#}

variable "dataops-utility_chart_version" {
  type = string
}

variable "dataops-utility_app_version" {
  type = string
}

variable "dataset-neo4j_chart_version" {
  type = string
}

variable "dataset-neo4j_app_version" {
  type = string
}

variable "notification_chart_version" {
  type = string
}

variable "notification_app_version" {
  type = string
}

variable "portal_chart_version" {
  type = string
}

variable "portal_app_version" {
  type = string
}

variable "maintenance-page_chart_version" {
  type = string
}

variable "maintenance-page_app_version" {
  type = string
}

variable "provenance_chart_version" {
  type = string
}

variable "provenance_app_version" {
  type = string
}

variable "dataset_chart_version" {
  type = string
}

variable "dataset_app_version" {
  type = string
}

variable "encryption_chart_version" {
  type = string
}

variable "encryption_app_version" {
  type = string
}

variable "download_chart_version" {
  type = string
}

variable "download_app_version" {
  type = string
}

variable "pipelinewatch_chart_version" {
  type = string
}

variable "upload_chart_version" {
  type = string
}

variable "upload_app_version" {
  type = string
}

variable "queue-consumer_chart_version" {
  type = string
}

variable "queue-consumer_app_version" {
  type = string
}

variable "queue-producer_chart_version" {
  type = string
}

variable "queue-producer_app_version" {
  type = string
}

variable "queue-socketio_chart_version" {
  type = string
}

variable "queue-socketio_app_version" {
  type = string
}

variable "frontend-vre-home_chart_version" {
  type = string
}

variable "frontend-vre-home_app_version" {
  type = string
}
variable "repository" {
  type = string
}
variable "neo4j_chart_version" {
  type = string
}

variable "neo4j_admin_username" {
  type        = string
  default     = "neo4j"
  description = "default admin username used to connect to neo4j"
}

variable "neo4j_admin_password" {
  type        = string
  default     = "mysupersavepassword"
  description = "default admin password to neo4j"
  sensitive   = true
}

variable "postgresql-ha_chart_version" {
  type = string
}

variable "vault_chart_version" {
  type = string
}

variable "keycloak_chart_version" {
  type = string
}

variable "kong_chart_version" {
  type = string
}

variable "kong_keycloak_client_id" {
  type    = string
  default = "kong"
}

variable "minio_chart_version" {
  type        = string
  description = "Version of the MinIO installation. Applies to both operator and tenant chart."
}

variable "ghcr_token" {
  type      = string
  sensitive = true
}

variable "vault_token" {
  type      = string
  sensitive = true
}

variable "vault-server-certificate-name" {
  type        = string
  description = "The secret name in which vaults server certificate is being stored"
  default     = "vault-server-certificate"
}

variable "postgres_password" {
  type      = string
  sensitive = true
  default   = "postgres"
}

variable "postgresql_password" {
  type      = string
  sensitive = true
  default   = "postgres"
}

variable "pgpool_admin_password" {
  type      = string
  sensitive = true
  default   = "postgres"
}

variable "repmgr_password" {
  type      = string
  sensitive = true
  default   = "postgres"
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_admin_username" {
  type        = string
  default     = "admin"
  description = "name of the initial admin user"
}

variable "keycloak_db_username" {
  type        = string
  default     = "keycloak"
  description = "username keycloak uses to connect itself to the db"
}

variable "keycloak_db" {
  type        = string
  default     = "keycloak"
  description = "keycloak database"
}

variable "postgresql_db_port" {
  type        = string
  default     = "5432"
  description = "default postgresql database port"
}

variable "opsdb_admin_username" {
  type        = string
  default     = "postgres"
  description = "default admin username used to connect to the opsdb"
}

variable "opsdb_indoc_vre_username" {
  type        = string
  default     = "indoc_vre"
  description = "default username for the indoc_vre user"
}

variable "service_approval_password" {
  type      = string
  sensitive = true
  default   = "approval"
}

variable "service_notification_password" {
  type      = string
  sensitive = true
  default   = "notification"
}

variable "service_dataset_password" {
  type      = string
  sensitive = true
  default   = "dataset"
}

variable "service_auth_password" {
  type      = string
  sensitive = true
  default   = "auth"
}

variable "service_entityinfo_password" {
  type      = string
  sensitive = true
  default   = "entityinfo"
}

variable "service_dataops_utility_password" {
  type      = string
  sensitive = true
  default   = "dataops_utility"
}

variable "service_encription_password" {
  type      = string
  sensitive = true
  default   = "encription"
}

variable "minio_operator_namespace" {
  type    = string
  default = "minio-operator"
}

variable "minio_tenant_namespaces" {
  type    = set(string)
  default = ["minio"]
}

variable "minio_keycloak_client_id" {
  type        = string
  default     = "minio"
  description = "The name of the client created in keycloak used by minio. Maps to the client name / client-id in keycloak"
}

variable "ngnix_ingress_controller_version" {
  type    = string
  default = "1.3.2"
}

variable "rabbitmq_username" {
  type      = string
  sensitive = true
  default   = "rabbitmq"
}

variable "rabbitmq_password" {
  type      = string
  sensitive = true
  default   = "rabbitmq"
}

variable "openldap_chart_version" {
  type = string
}
