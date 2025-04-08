terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
  }

  backend "kubernetes" {
    secret_suffix = "intermediary-install"
  }
}
