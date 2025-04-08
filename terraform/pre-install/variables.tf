variable "kubeconfig" {
  type        = string
  default     = "~/.kube/config"
  description = "Path to the kubeconfig file"
}

variable "ghcr_token" {
  type      = string
  sensitive = true
}

variable "vault_token" {
  type      = string
  sensitive = true
}

variable "helm_wait" {
  type        = bool
  default     = true
  description = "Will wait until all helm-release resources are in a ready state before marking the release as successful."
}

variable "helm_verify" {
  type        = bool
  default     = false
  description = " Verify the package before installing it."
}

variable "helm_atomic" {
  type        = bool
  default     = true
  description = "If set, installation process purges chart on fail. The wait flag will be set automatically if atomic is used"
}

variable "helm_cleanup_on_fail" {
  type        = bool
  default     = true
  description = "Allow deletion of new resources created in this upgrade when upgrade fails"
}

variable "env" {
  type    = string
  default = "charite"
}

variable "ngnix_ingress_controller_version" {
  type    = string
  default = "1.3.2"
}
