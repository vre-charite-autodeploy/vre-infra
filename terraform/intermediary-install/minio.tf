# this must exist before the operator is installed
# https://min.io/docs/minio/kubernetes/upstream/operations/cert-manager/cert-manager-operator.html
resource "kubernetes_manifest" "cert_manager_operator_server_certificate" {
  depends_on = [kubernetes_manifest.cert_manager_vre_root_certificate_cluster_issuer]

  manifest = yamldecode(<<EOT
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: sts-certmanager-cert
      namespace: ${var.minio_operator_namespace}
    spec:
      dnsNames:
        - sts
        - sts.${var.minio_operator_namespace}.svc
        - sts.${var.minio_operator_namespace}.svc.cluster.local # Replace cluster.local with the value for your domain.
      secretName: sts-tls # secret *must* be named this
      issuerRef:
        name: vre-pki-cluster-issuer
        kind: ClusterIssuer
        group: cert-manager.io
  EOT
  )
}

# this must exist before the tenant is installed
# https://min.io/docs/minio/kubernetes/upstream/operations/cert-manager/cert-manager-tenants.html
resource "kubernetes_manifest" "cert_manager_tenant_server_certificate" {
  depends_on = [kubernetes_manifest.cert_manager_vre_root_certificate_cluster_issuer]

  for_each = var.minio_tenant_namespaces
  manifest = yamldecode(<<EOT
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: tenant-certmanager-cert
      namespace: ${each.value}
    spec:
      dnsNames:
        - "minio-hl.${each.value}"
        - "minio-hl.${each.value}.svc"
        - "minio-hl.${each.value}.svc.cluster"
        - 'minio-hl.${each.value}.svc.cluster.local'
        - "*.minio-hl.${each.value}"
        - "*.minio-hl.${each.value}.svc"
        - '*.minio-hl.${each.value}.svc.cluster'
        - '*.minio-hl.${each.value}.svc.cluster.local'
      secretName: minio-tls
      issuerRef:
        name: vre-pki-cluster-issuer
        kind: ClusterIssuer
        group: cert-manager.io
  EOT
  )
}
