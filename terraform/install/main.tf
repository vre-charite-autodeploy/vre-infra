terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

  }

  backend "kubernetes" {
    secret_suffix = "install"
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

provider "kubernetes" {
  config_path = var.kubeconfig
}

module "ingress_data" {
  source = "../modules/data-ingress"
}
