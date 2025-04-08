variable "minio_operator_namespace" {
  type    = string
  default = "minio-operator"
}

variable "minio_tenant_namespaces" {
  type    = set(string)
  default = ["minio"]
}

variable "env" {
  type    = string
  default = "charite"
}
