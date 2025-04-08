locals {
  atlas_namespace  = "utility"
  atlas_name       = "atlas"
  atlas_svc_port   = 21000
  atlas_admin_user = "admin"
}

locals {
  atlas_svc_host = "${local.atlas_name}.${local.atlas_namespace}.svc.cluster.local"
}

locals {
  atlas_pod_host = "${local.atlas_name}-0.${local.atlas_svc_host}"
}

resource "kubernetes_manifest" "atlas_health_check" {
  manifest = yamldecode(<<EOT
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: "atlas-health-check"
      namespace: ${local.atlas_namespace}
    data:
      health-check.sh: |
        </dev/tcp/localhost/21000 && \
        </dev/tcp/localhost/2181 && \
        </dev/tcp/localhost/9838 && \
        </dev/tcp/localhost/61510 && \
        </dev/tcp/localhost/61530
  EOT
  )
}

resource "random_password" "atlas_admin_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret_v1" "atlas_admin_credentials" {
  metadata {
    name      = "atlas-admin-credentials"
    namespace = local.atlas_namespace
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username : local.atlas_admin_user
    password_hash : sha256(random_password.atlas_admin_password.result)
  }
}

resource "kubernetes_config_map_v1" "atlas_managed_schema" {
  metadata {
    name      = "atlas-managed-schema"
    namespace = local.atlas_namespace
  }

  data = {
    "managed-schema" = file("${path.module}/script/atlas/managed-schema")
  }
}

resource "kubernetes_config_map_v1" "atlas_admin_credentials_config" {
  metadata {
    name      = "atlas-admin-credentials"
    namespace = local.atlas_namespace
  }

  data = {
    "credentials-config.sh" = <<EOT
      file_path="/opt/apache-atlas-2.1.0/conf/users-credentials.properties"
      # Line to search for and replace
      search_pattern="^$ADMIN_USERNAME=ADMIN"
      new_line="$ADMIN_USERNAME=ADMIN::$ADMIN_PASSWORD_HASH"

      # Check if the file contains a line starting with '$ADMIN_USERNAME=ADMIN'
      if grep -q "$search_pattern" "$file_path"; then
          # Replace the line
          sed -i "s|$search_pattern.*|$new_line|" "$file_path"
      else
          # Append the line to the file
          echo "$new_line" >> "$file_path"
      fi
    EOT
  }
}

resource "kubernetes_manifest" "atlas_statefulset" {
  manifest = yamldecode(<<EOF
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: ${local.atlas_name}
      namespace: ${local.atlas_namespace}
      labels:
        app: ${local.atlas_name}
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: ${local.atlas_name}
      serviceName: ${local.atlas_name}
      template:
        metadata:
          labels:
            app: ${local.atlas_name}
        spec:
          initContainers:
            - name: atlas-copy-conf
              image: ghcr.io/vre-charite/kubernetes/atlas:apache-atlas-2.1.0
              imagePullPolicy: Always
              command: ["/bin/bash", "-c"]
              args:
                - |
                  cp -baru /opt/apache-atlas-2.1.0/conf/ /
              volumeMounts:
                - mountPath: /conf
                  name: atlas-config
              resources:
                requests:
                  memory: "500Mi"
                  cpu: "200m"
                limits:
                  memory: "1000Mi"
                  cpu: "800m"
            - name: atlas-setup
              image: ghcr.io/vre-charite/kubernetes/atlas:apache-atlas-2.1.0
              imagePullPolicy: Always
              env:
                - name: LOG4J_FORMAT_MSG_NO_LOOKUPS
                  value: "true"
                - name: ATLAS_SERVER_HEAP
                  value: "-Xms15360m -Xmx15360m -XX:MaxNewSize=5120m -XX:MetaspaceSize=100M -XX:MaxMetaspaceSize=512m"
                - name: ATLAS_OPTS
                  value: "-Datlas.kafka.zookeeper.session.timeout.ms=60000"
                - name: ADMIN_USERNAME
                  valueFrom:
                    secretKeyRef:
                      name: ${kubernetes_secret_v1.atlas_admin_credentials.metadata[0].name}
                      key: username
                - name: ADMIN_PASSWORD_HASH
                  valueFrom:
                    secretKeyRef:
                      name: ${kubernetes_secret_v1.atlas_admin_credentials.metadata[0].name}
                      key: password_hash
              command: ["/bin/bash", "-c"]
              args:
                - |
                  # Check if the setup has been performed previously.
                  if [ ! -f /opt/apache-atlas-2.1.0/data/setup_completed ]; then
                    echo "Performing initial setup..."
                    /opt/apache-atlas-2.1.0/bin/atlas_start.py -setup
                    echo "Create Admin Login"
                    /root/credentials-config.sh
                    # Create file to indicate that the setup has been done.
                    echo "Create setup_completed file"
                    touch /opt/apache-atlas-2.1.0/data/setup_completed
                  else
                    echo "Setup already completed skipping setup..."
                  fi
              resources:
                requests:
                  memory: "3000Mi"
                  cpu: "200m"
                limits:
                  memory: "5000Mi"
                  cpu: "800m"
              volumeMounts:
                - mountPath: /opt/apache-atlas-2.1.0/data
                  name: atlas-data
                - mountPath: /opt/apache-atlas-2.1.0/conf
                  name: atlas-config
                - mountPath: /opt/apache-atlas-2.1.0/solr/server/solr/edge_index_shard1_replica_n1/data
                  name: atlas-solr-entity-1
                - mountPath: /opt/apache-atlas-2.1.0/solr/server/solr/fulltext_index_shard1_replica_n1/data
                  name: atlas-solr-entity-2
                - mountPath: /opt/apache-atlas-2.1.0/solr/server/solr/vertex_index_shard1_replica_n1/data
                  name: atlas-solr-entity-3
                - mountPath: /opt/apache-atlas-2.1.0/logs
                  name: atlas-log
                - mountPath: /opt/apache-atlas-2.1.0/solr/server/solr/configsets/_default/conf/managed-schema
                  subPath: managed-schema
                  name: managed-schema
                - mountPath: /root/health-check.sh
                  subPath: health-check.sh
                  name: health-check
                  readOnly: true
                - mountPath: /root/credentials-config.sh
                  subPath: credentials-config.sh
                  name: credentials
                  readOnly: true
          containers:
            - name: ${local.atlas_name}
              image: ghcr.io/vre-charite/kubernetes/atlas:apache-atlas-2.1.0
              imagePullPolicy: Always
              env:
                - name: LOG4J_FORMAT_MSG_NO_LOOKUPS
                  value: "true"
                - name: ATLAS_SERVER_HEAP
                  value: " -Xms4096m -Xmx5120m"
                - name: ATLAS_OPTS
                  value: "-Datlas.kafka.zookeeper.session.timeout.ms=60000"
                - name: ADMIN_USERNAME
                  valueFrom:
                    secretKeyRef:
                      name: atlas-admin-credentials
                      key: username
                - name: ADMIN_PASSWORD_HASH
                  valueFrom:
                    secretKeyRef:
                      name: atlas-admin-credentials
                      key: password_hash
              command: ["/opt/apache-atlas-2.1.0/bin/atlas_start.py"]
              ports:
                - containerPort: ${local.atlas_svc_port}
                - containerPort: 9838
                - containerPort: 2181
              volumeMounts:
                - mountPath: /opt/apache-atlas-2.1.0/data
                  name: atlas-data
                - mountPath: /opt/apache-atlas-2.1.0/conf
                  name: atlas-config
                - mountPath: /opt/apache-atlas-2.1.0/solr/server/solr/edge_index_shard1_replica_n1/data
                  name: atlas-solr-entity-1
                - mountPath: /opt/apache-atlas-2.1.0/solr/server/solr/fulltext_index_shard1_replica_n1/data
                  name: atlas-solr-entity-2
                - mountPath: /opt/apache-atlas-2.1.0/solr/server/solr/vertex_index_shard1_replica_n1/data
                  name: atlas-solr-entity-3
                - mountPath: /opt/apache-atlas-2.1.0/solr/server/solr/configsets/_default/conf/managed-schema
                  subPath: managed-schema
                  name: managed-schema
                - mountPath: /opt/apache-atlas-2.1.0/logs
                  name: atlas-log
                - mountPath: /root/health-check.sh
                  subPath: health-check.sh
                  name: health-check
                  readOnly: true
                - mountPath: /root/credentials-config.sh
                  subPath: credentials-config.sh
                  name: credentials
                  readOnly: true
              livenessProbe:
                exec:
                  command:
                    - /bin/bash
                    - /root/health-check.sh
                failureThreshold: 5
                initialDelaySeconds: 1200
                periodSeconds: 5
                successThreshold: 1
              readinessProbe:
                tcpSocket:
                  port: 21000
                initialDelaySeconds: 120
                periodSeconds: 10
                failureThreshold: 3
              resources:
                requests:
                  memory: "4Gi"
                  cpu: "200m"
                limits:
                  memory: "5248Mi"
                  cpu: "800m"
          terminationGracePeriodSeconds: 60
          volumes:
            - name: health-check
              configMap:
                name: ${kubernetes_manifest.atlas_health_check.manifest["metadata"]["name"]}
                defaultMode: 511
                items:
                  - key: health-check.sh
                    path: health-check.sh
            - name: managed-schema
              configMap:
                name: ${kubernetes_config_map_v1.atlas_managed_schema.metadata[0].name}
                items:
                  - key: managed-schema
                    path: managed-schema
            - name: credentials
              configMap:
                name: ${kubernetes_config_map_v1.atlas_admin_credentials_config.metadata[0].name}
                defaultMode: 511
                items:
                  - key: credentials-config.sh
                    path: credentials-config.sh
      volumeClaimTemplates:
        - metadata:
            name: atlas-data
          spec:
            storageClassName: cinder-csi
            accessModes:
              - ReadWriteMany
            resources:
              requests:
                storage: 2Gi
        - metadata:
            name: atlas-config
          spec:
            storageClassName: cinder-csi
            accessModes:
              - ReadWriteMany
            resources:
              requests:
                storage: 500Mi
        - metadata:
            name: atlas-solr-entity-1
          spec:
            storageClassName: cinder-csi
            accessModes:
              - ReadWriteMany
            resources:
              requests:
                storage: 2Gi
        - metadata:
            name: atlas-solr-entity-2
          spec:
            storageClassName: cinder-csi
            accessModes:
              - ReadWriteMany
            resources:
              requests:
                storage: 2Gi
        - metadata:
            name: atlas-solr-entity-3
          spec:
            storageClassName: cinder-csi
            accessModes:
              - ReadWriteMany
            resources:
              requests:
                storage: 2Gi
        - metadata:
            name: atlas-log
          spec:
            storageClassName: cinder-csi
            accessModes:
              - ReadWriteMany
            resources:
              requests:
                storage: 5Gi
    EOF
  )

  wait {
    fields = {
      "status.readyReplicas" = "1"
    }
  }

  timeouts {
    create = "22m"
  }
}

resource "kubernetes_manifest" "atlas-service" {
  depends_on = [kubernetes_manifest.atlas_statefulset]
  manifest = yamldecode(<<EOF
  apiVersion: v1
  kind: Service
  metadata:
    name: ${local.atlas_name}
    namespace: ${local.atlas_namespace}
  spec:
    ports:
      - port: ${local.atlas_svc_port}
        protocol: TCP
        targetPort: ${local.atlas_svc_port}
        name: "${local.atlas_svc_port}"
    selector:
      app: ${local.atlas_name}
    type: ClusterIP
  EOF
  )
}
