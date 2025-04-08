module "namespaces" {
  for_each       = toset(["utility", "greenroom", "minio", "minio-operator", "vre", "vault", "cert-manager", "ingress", "observability"])
  source         = "./modules/namespace"
  namespace_name = each.value
  ghcr_token     = var.ghcr_token
  vault_token    = var.vault_token
}

resource "helm_release" "cert-manager" {
  depends_on = [module.namespaces]

  name = "cert-manager"

  repository      = "https://charts.jetstack.io"
  chart           = "cert-manager"
  namespace       = "cert-manager"
  version         = "v1.16.2"
  timeout         = "300"
  wait            = var.helm_wait
  verify          = var.helm_verify
  atomic          = var.helm_atomic
  cleanup_on_fail = var.helm_cleanup_on_fail

  # cf. https://github.com/cert-manager/cert-manager/blob/v1.16.2/deploy/charts/cert-manager/values.yaml
  values = [file("./helm/cert-manager/${var.env}/values.yaml")]
}

resource "helm_release" "trust_manager" {
  depends_on = [module.namespaces, helm_release.cert-manager]

  name = "trust-manager"

  repository      = "https://charts.jetstack.io"
  chart           = "trust-manager"
  version         = "v0.13.0"
  namespace       = "cert-manager"
  timeout         = "300"
  wait            = var.helm_wait
  verify          = var.helm_verify
  atomic          = var.helm_atomic
  cleanup_on_fail = var.helm_cleanup_on_fail

  # cf. https://github.com/cert-manager/trust-manager/blob/v0.13.0/deploy/charts/trust-manager/values.yaml
  values = [file("./helm/trust-manager/${var.env}/values.yaml")]
}
