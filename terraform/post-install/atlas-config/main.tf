
resource "kubernetes_config_map_v1" "atlas_custom_entity" {
  metadata {
    name      = "atlas-custom-entity"
    namespace = var.atlas_namespace
  }
  data = {
    "entity.json" = file("${path.module}/script/atlas/entity.json")
  }
}

resource "kubernetes_manifest" "atlas_config_job" {

  manifest = yamldecode(<<EOF
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: atlas-config
      namespace: ${var.atlas_namespace}
    spec:
      backoffLimit: 20
      template:
        spec:
          restartPolicy: OnFailure
          volumes:
            - name: script
              configMap:
                name: ${kubernetes_config_map_v1.atlas_custom_entity.metadata[0].name}
                defaultMode: 511
          containers:
            - name: atlas-config
              image: alpine/curl
              volumeMounts:
                - name: script
                  mountPath: /scripts
                  readOnly: true
              command:
                - "sh"
                - "-ec"
              args:
                - |
                  curl -u $ATLAS_USER:$ATLAS_PASSWORD --noproxy '*' -X POST -H "Content-Type: application/json" -d @/scripts/entity.json "http://$ATLAS_NAME:$ATLAS_PORT/api/atlas/v2/types/typedefs"

              env:
                - name: ATLAS_USER
                  value: ${var.atlas_admin_username}
                - name: ATLAS_PASSWORD
                  value: ${var.atlas_admin_password}
                - name: ATLAS_NAME
                  value: "${var.atlas_name}"
                - name: ATLAS_PORT
                  value: "${var.atlas_port}"
    EOF
  )

}
