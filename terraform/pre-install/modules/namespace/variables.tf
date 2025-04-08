variable "namespace_name" {
  type = string
}

variable "ghcr_token" {
  type      = string
  sensitive = true
}

variable "vault_token" {
  type      = string
  sensitive = true
}
