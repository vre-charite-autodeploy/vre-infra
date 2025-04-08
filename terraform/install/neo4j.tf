locals {
  neo4j_namespace = "utility"
  neo4j_db_name   = "neo4j-db"
}

resource "random_password" "neo4j" {
  length  = 16
  upper   = true
  lower   = true
  special = false
}

resource "helm_release" "neo4j" {
  depends_on = [kubernetes_secret.neo4j_admin_credentials]

  name = local.neo4j_db_name

  repository = "https://helm.neo4j.com/neo4j"
  chart      = "neo4j"
  version    = var.neo4j_chart_version
  namespace  = "utility"
  timeout    = "300"
  wait       = var.helm-wait

  values = [file("../../helm/neo4j/${var.env}/values.yaml")]

  set {
    name  = "neo4j.passwordFromSecret"
    value = "neo4j-admin-credentials"
  }
}

resource "kubernetes_secret" "neo4j_admin_credentials" {
  metadata {
    name      = "neo4j-admin-credentials"
    namespace = "utility"
  }

  data = {
    username   = var.neo4j_admin_username
    password   = random_password.neo4j.result
    NEO4J_AUTH = "${var.neo4j_admin_username}/${random_password.neo4j.result}"
  }
}

resource "kubernetes_config_map_v1" "neo4j_scripts" {
  metadata {
    name      = "neo4j-scripts"
    namespace = local.neo4j_namespace
  }

  data = {
    "user_admin.cypher" = <<EOT
        MERGE (
            u:User {global_entity_id: 'e25a09aa-919f-11eb-ac2b-ee9477001436-1617140144', 
            announcement_indoctestproject: 7, 
            path: 'users',  
            role: $ROLE,
            name: $ROLE, 
            last_name: $ROLE, 
            first_name: $ROLE, 
            email: $EMAIL, 
            username: $ROLE, 
            status: 'active'}) 
        ON CREATE
        SET 
            u.time_lastmodified = toString(datetime()),
            u.last_login = toString(datetime())
  
        RETURN u;
      EOT
  }
}

resource "kubernetes_manifest" "neo4j_init_db_job" {
  depends_on = [helm_release.neo4j]

  manifest = yamldecode(<<EOF
      apiVersion: batch/v1
      kind: Job
      metadata:
        name: neo4j-init-db-job
        namespace: ${local.neo4j_namespace}
      spec:
        backoffLimit: 20
        template:
          spec:
            restartPolicy: OnFailure
            volumes:
              - name: script
                configMap:
                  name: ${kubernetes_config_map_v1.neo4j_scripts.metadata[0].name}
                  defaultMode: 511
            containers:
              - name: neo4j-init-db
                image: amazoncorretto:17
                volumeMounts:
                  - name: script
                    mountPath: /scripts
                    readOnly: true
                command:
                  - "sh"
                  - "-ec"
                args:
                  - |
                    yum install which -y
                    curl -O https://dist.neo4j.org/cypher-shell/cypher-shell-5.26.1-1.noarch.rpm
                    rpm -i cypher-shell-5.26.1-1.noarch.rpm 
                    cypher-shell -u $NEO4J_USER -p $NEO4J_PASSWORD -a $NEO4J_HOST -f /scripts/user_admin.cypher --param "ROLE => '$NEO4J_ADMIN_ROLE_NAME'" --param "EMAIL => '$NEO4J_ADMIN_EMAIL'"
                env:
                  - name: NEO4J_USER
                    valueFrom:
                      secretKeyRef:
                        name: ${kubernetes_secret.neo4j_admin_credentials.metadata[0].name}
                        key: username
                  - name: NEO4J_PASSWORD
                    valueFrom:
                      secretKeyRef:
                        name: ${kubernetes_secret.neo4j_admin_credentials.metadata[0].name}
                        key: password
                  - name: NEO4J_HOST
                    value: "bolt://${local.neo4j_db_name}:7687"
                  - name: NEO4J_ADMIN_ROLE_NAME
                    value: "admin"
                  - name: NEO4J_ADMIN_EMAIL
                    value: "vre-admin@charite.de"

    EOF

  )
}
