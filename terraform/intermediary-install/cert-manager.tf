resource "kubernetes_manifest" "cert_manager_self_signed_issuer" {
  manifest = yamldecode(<<EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: selfsigned-issuer
    spec:
      selfSigned: {}
  EOF
  )
}

resource "kubernetes_manifest" "cert_manager_vre_root_certificate" {
  manifest = yamldecode(<<EOF
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: vre-root-certificate
      namespace: cert-manager
    spec:
      isCA: true
      commonName: system:node:self.signed
      secretName: vre-root-certificate
      privateKey:
        algorithm: ECDSA
        size: 256
      duration: 87600h # ~10y
      renewBefore: 360h # 15d
      # We are setting this on our self-signed root certificate to guarantee compatibility with TLS libraries client-side
      # that verify the server certificate and the validity (well-formedness) of the certificate chain, incl. this root
      # certificate.
      # cf. https://cert-manager.io/docs/configuration/selfsigned/#certificate-validity
      subject:
        countries:
          - "DE"
        localities:
          - "Berlin"
        organizations:
          - "Charité Universitätsmedizin Berlin"
        organizationalUnits:
          - "VRE"
      issuerRef:
        name: selfsigned-issuer
        kind: ClusterIssuer
        group: cert-manager.io
  EOF
  )
}

# Use this cluster issuer with other applications in order to obtain server certificates
# Hint: When creating a certificate resource that's ought to be issued by our root, set the `issuerRef` as follows
# -----
# issuerRef:
#   name: vre-pki-cluster-issuer
#   kind: ClusterIssuer
#   group: cert-manager.io
resource "kubernetes_manifest" "cert_manager_vre_root_certificate_cluster_issuer" {
  manifest = yamldecode(<<EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: vre-pki-cluster-issuer
    spec:
      ca:
        secretName: vre-root-certificate
  EOF
  )
}
