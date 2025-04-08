terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
  }

  backend "kubernetes" {
    secret_suffix = "pre-install"
  }
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig
  }

  registry {
    url      = "oci://ghcr.io/vre-charite-autodeploy"
    username = split(":", var.ghcr_token)[0]
    password = split(":", var.ghcr_token)[1]
  }
}
