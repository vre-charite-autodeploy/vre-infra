locals {
  opsdb_name      = "opsdb"
  opsdb_namespace = "utility"
  indoc_vre_db    = "indoc_vre"
  postgres_db_uri = "postgresql://${var.opsdb_indoc_vre_username}:${random_password.opsdb_password.result}@${local.opsdb_name}.${local.opsdb_namespace}:${var.postgresql_db_port}/${local.indoc_vre_db}"
}

resource "random_password" "opsdb_password" {
  length = 16
}

resource "kubernetes_secret" "opsdb_admin" {
  metadata {
    name      = "opsdb-admin"
    namespace = local.opsdb_namespace
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.opsdb_admin_username
    password = random_password.opsdb_password.result
  }
}

resource "kubernetes_secret" "opsdb_indoc_vre" {
  for_each = toset([local.opsdb_namespace, "greenroom"])
  metadata {
    name      = "opsdb-indoc-vre"
    namespace = each.value
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.opsdb_indoc_vre_username
    password = random_password.opsdb_password.result
    uri      = local.postgres_db_uri
  }
}

resource "kubernetes_config_map_v1" "opsdb_scripts" {
  metadata {
    name      = "opsdb-scripts"
    namespace = local.opsdb_namespace
  }

  data = {
    "init_db.sql" = file("${path.module}/script/opsdb/init_db.sql")
  }
}

resource "kubernetes_manifest" "opsdb_statefulset" {
  field_manager {
    force_conflicts = true
  }
  manifest = yamldecode(<<EOF
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: ${local.opsdb_name}
      namespace:  ${local.opsdb_namespace}
    spec:
      replicas: 1
      serviceName: ${local.opsdb_name}
      selector:
        matchLabels:
          app: ${local.opsdb_name}
      template:
        metadata:
          labels:
            app: ${local.opsdb_name}
        spec:
          containers:
          - env:
            - name: POSTGRES_DB
              value: ${local.indoc_vre_db}
            - name: INDOC_VRE_USER
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.opsdb_indoc_vre[local.opsdb_namespace].metadata[0].name}
                  key: username 
            - name: INDOC_VRE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.opsdb_indoc_vre[local.opsdb_namespace].metadata[0].name}
                  key: password
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.opsdb_admin.metadata[0].name}
                  key: username
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.opsdb_admin.metadata[0].name}
                  key: password

            - name: KEYCLOAK_USER
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.keycloak_db.metadata[0].name}
                  key: username
            - name: KEYCLOAK_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.keycloak_db.metadata[0].name}
                  key: password
            - name: KEYCLOAK_DB
              value:  ${var.keycloak_db}
            image: postgres:9.5
            name: postgres
            lifecycle:
                postStart:
                  exec:
                    command:
                      - "sh"
                      - "-c"
                      - |
                        
                        MAX_RETRIES=5
                        RETRY_COUNT=0

                        until psql -U postgres -c "SELECT 1" > /dev/null 2>&1 || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
                            echo "Waiting for PostgreSQL to be ready... ($RETRY_COUNT/$MAX_RETRIES)"
                            RETRY_COUNT=$((RETRY_COUNT+1))
                            sleep 10
                        done

                        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
                            echo "Failed to connect to PostgreSQL after $MAX_RETRIES attempts"
                            exit 1
                        fi
                        psql -U postgres -a -f ./script/init_db.sql -v KEYCLOAK_DB=$KEYCLOAK_DB -v KEYCLOAK_USER=$KEYCLOAK_USER -v KEYCLOAK_PASSWORD=$KEYCLOAK_PASSWORD -v INDOC_DB=$POSTGRES_DB -v INDOC_USER=$INDOC_VRE_USER -v INDOC_PASSWORD=$INDOC_VRE_PASSWORD;
            ports:
            - containerPort:  ${var.postgresql_db_port}
            volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: opsdb
              subPath: pgdata
            - name: script
              mountPath: /script
              readOnly: true
            readinessProbe:
              tcpSocket:
                port:  ${var.postgresql_db_port}
              initialDelaySeconds: 5
              periodSeconds: 10
            resources:
              requests:
                memory: "2Gi"
                cpu: "2"
              limits:
                memory: "8Gi"
                cpu: "2"
          terminationGracePeriodSeconds: 60
          volumes:
            - name: script
              configMap:
                name: ${kubernetes_config_map_v1.opsdb_scripts.metadata[0].name}
                defaultMode: 511
      volumeClaimTemplates:
      - metadata:
          name: opsdb
          annotations:
            volume.beta.kubernetes.io/storage-class: cinder-csi
        spec:
          accessModes:
          - ReadWriteOnce
          resources:
            requests:
              storage: 4Gi

  EOF
  )
}

resource "kubernetes_manifest" "opsdb_service" {
  manifest = yamldecode(<<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: ${local.opsdb_name}
      namespace: ${local.opsdb_namespace}
      labels:
        app: ${local.opsdb_name}
    spec:
      ports:
      - name: psql
        port: ${var.postgresql_db_port}
        protocol: TCP
        targetPort: ${var.postgresql_db_port}
      selector:
        app: ${local.opsdb_name}
      type: ClusterIP
    EOF
  )
}
