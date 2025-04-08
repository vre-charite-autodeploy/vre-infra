locals {
  keycloak_namespace         = "utility"
  keycloak_antd_pvc_name     = "keycloak-antd"
  keycloak_auth_ext_pvc_name = "keycloak-auth-extension"
}

resource "kubernetes_manifest" "keycloak_service" {
  manifest = yamldecode(<<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: keycloak
      namespace: ${local.keycloak_namespace}
      labels:
        app: keycloak
    spec:
      ports:
      - name: http
        port: 80
        targetPort: http
      selector:
        app: keycloak
      type: ClusterIP
  EOF
  )
}

resource "kubernetes_manifest" "keycloak_deployment" {
  depends_on = [
    kubernetes_manifest.keycloak_antd_pvc,
    kubernetes_manifest.keycloak_auth_extension_pvc
  ]

  manifest = yamldecode(<<EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: keycloak
      namespace: ${local.keycloak_namespace}
      labels:
        app: keycloak
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: keycloak
      template:
        metadata:
          labels:
            app: keycloak
        spec:
          containers:
          - name: keycloak
            image: ghcr.io/vre-charite/keycloak:10.0.2
            env:
            - name: DB_VENDOR
              value: "postgres"
            - name: KEYCLOAK_USER
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.keycloak_admin.metadata[0].name}
                  key: username
            - name: KEYCLOAK_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.keycloak_admin.metadata[0].name}
                  key: password
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.keycloak_db.metadata[0].name}
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: ${kubernetes_secret.keycloak_db.metadata[0].name}
                  key: password
            - name: DB_ADDR
              value: "opsdb.utility"
            - name: DB_PORT
              value: ${var.postgresql_db_port}
            - name: DB_DATABASE
              value: ${var.keycloak_db}
            - name: JDBC_PARAMS
              value: "verifyServerCertificate=false&useSSL=false"
            - name: PROXY_ADDRESS_FORWARDING
              value: "true"
            - name: env
              value: "charite"
            - name: JAVA_OPTS
              value: "-Dkeycloak.profile.feature.token_exchange=enabled -Dkeycloak.profile.feature.scripts=enabled -Dkeycloak.profile.feature.upload_scripts=enabled -Dkeycloak.adminUrl=${module.ingress_data.domain_name_https}/vre/auth/ -Dkeycloak.frontendUrl=https://${module.ingress_data.domain_name}/vre/auth/"
            ports:
            - name: http
              containerPort: 8080
            readinessProbe:
              tcpSocket:
                port: 8080
              initialDelaySeconds: 5
              periodSeconds: 10
            resources:
              requests:
                memory: "1Gi"
                cpu: "500m"
              limits:
                memory: "2Gi"
                cpu: "500m"
            volumeMounts:
              - name: extensions
                mountPath: /opt/jboss/keycloak/standalone/deployments/
              - name: antd
                mountPath: /opt/jboss/keycloak/themes/keycloak-antd/
              - name: standalone-ha
                mountPath: /opt/jboss/keycloak/standalone/configuration/standalone-ha.xml
                subPath: standalone-ha.xml
              - name: standalone
                mountPath: /opt/jboss/keycloak/standalone/configuration/standalone.xml
                subPath: standalone.xml
              - name: index
                mountPath: /opt/jboss/keycloak/welcome-content/index.html
                subPath: index.html
              - name: messages-en
                mountPath: /opt/jboss/keycloak/themes/base/login/messages/messages_en.properties
                subPath: messages_en.properties
          volumes:
            - name: extensions
              persistentVolumeClaim:
                claimName: ${local.keycloak_auth_ext_pvc_name}
            - name: antd
              persistentVolumeClaim:
                claimName: ${local.keycloak_antd_pvc_name}
            - name: standalone-ha
              configMap:
                name: ${kubernetes_config_map_v1.keycloak_standalone_ha_xml.metadata[0].name}
            - name: standalone
              configMap:
                name: ${kubernetes_config_map_v1.keycloak_standalone_xml.metadata[0].name}
            - name: index
              configMap:
                name: ${kubernetes_config_map_v1.keycloak_index_html.metadata[0].name}
            - name: messages-en
              configMap:
                name: ${kubernetes_config_map_v1.keycloak_messages_en_properties.metadata[0].name}
  EOF
  )
}

resource "kubernetes_config_map_v1" "keycloak_messages_en_properties" {
  metadata {
    name      = "messages-en.properties"
    namespace = local.keycloak_namespace
  }
  data = {
    "messages_en.properties" = file("${path.module}/static/keycloak/messages_en.properties")
  }
}

resource "kubernetes_config_map_v1" "keycloak_index_html" {
  metadata {
    name      = "index.html"
    namespace = local.keycloak_namespace
  }
  data = {
    "index.html" = file("${path.module}/static/keycloak/index.html")
  }
}

resource "kubernetes_config_map_v1" "keycloak_standalone_xml" {
  metadata {
    name      = "standalone.xml"
    namespace = local.keycloak_namespace
  }
  data = {
    "standalone.xml" = file("${path.module}/static/keycloak/standalone.xml")
  }
}

resource "kubernetes_config_map_v1" "keycloak_standalone_ha_xml" {
  metadata {
    name      = "standalone-ha.xml"
    namespace = local.keycloak_namespace
  }
  data = {
    "standalone-ha.xml" = file("${path.module}/static/keycloak/standalone-ha.xml")
  }
}

resource "kubernetes_manifest" "keycloak_antd_pvc" {
  manifest = yamldecode(<<EOF
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      namespace: ${local.keycloak_namespace}
      name: ${local.keycloak_antd_pvc_name}
      annotations:
        volume.beta.kubernetes.io/storage-class: cinder-csi
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 3Gi
  EOF
  )
}

resource "kubernetes_manifest" "keycloak_auth_extension_pvc" {
  manifest = yamldecode(<<EOF
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      namespace: ${local.keycloak_namespace}
      name: ${local.keycloak_auth_ext_pvc_name}
      annotations:
        volume.beta.kubernetes.io/storage-class: cinder-csi
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
  EOF
  )
}

resource "kubernetes_secret" "keycloak_db" {
  metadata {
    name      = "keycloak-db"
    namespace = local.keycloak_namespace
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.keycloak_db_username
    password = random_password.keycloak_db.result
  }
}

resource "random_password" "keycloak_db" {
  length = 16
}

resource "kubernetes_secret" "keycloak_admin" {
  metadata {
    name      = "keycloak-admin"
    namespace = local.keycloak_namespace
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.keycloak_admin_username
    password = random_password.keycloak_admin.result
  }
}

resource "random_password" "keycloak_admin" {
  length = 16
}
