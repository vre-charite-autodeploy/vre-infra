# VRE DEPLOYMENT

## REQUIREMENTS

* [ ] A Kubernetes cluster
* [ ] Local tools installed for deploying
* [ ] Valid Github Personal Access Token (PAT)

<details><summary><b>Kubernetes</b></summary>

* [ ] Any kubernetes cluster (vanilla or from a distribution, <= 1.29.X) + accessible via kubeconfig from the machine you want deploy vre from
* [ ] Storageprovider/class (RMO/RWX) is already configured on the cluster (PVC can be created / will be bound)
* [ ] Services from LoadBalancer can be created (e.g. Cloud Provider based, HW, CiliumLB or MetalLB is installed on cluster and/or configured)

</details>

<details><summary><b>Tools</b></summary>

| Tool       | Example Version | Download Link                                                        | Used For                                                                 |
|------------|----------------|----------------------------------------------------------------------|--------------------------------------------------------------------------|
| Terraform  | v1.10.5         | [Terraform Downloads](https://www.terraform.io/downloads.html)        | Automates the provisioning and configuration of VRE.       |
| Helm       | v3.17.0         | [Helm Install](https://helm.sh/docs/intro/install/)                    | Verify Helm Releases. |
| Kubectl    | v1.32.3         | [Kubectl Downloads](https://kubernetes.io/docs/tasks/tools/)           | Provides command-line control over the Kubernetes clusters.                  |
| k9s        | v0.40.5         | [k9s Releases](https://github.com/derailed/k9s/releases)               | Offers a terminal UI to monitor and troubleshoot Kubernetes resources.   |

</details>

<details><summary><b>Token</b></summary>

To create a Personal Access Token on GitHub with the required permissions:

* Log in to your GitHub account.
* Click your profile picture in the top-right corner and select Settings.
* In the left sidebar, scroll down to Developer settings.
* Choose Personal access tokens, then:
  * click Tokens (classic) and then Generate new token.
  * After that, select the permissions you need (such as repo, workflow, write:packages, etc.), and then generate the token. Copy and store it securely.

```bash
Repository Permissions (repo)
✅ repo (Full control of private repositories)
✅ repo:status (Access commit status)
✅ repo_deployment (Access deployment status)
✅ public_repo (Access public repositories)
✅ repo:invite (Access repository invitations)
✅ security_events (Read and write security events)
✅ read:repo_hook (Read repository hooks)

Workflow Permissions
✅ workflow (Update GitHub Action workflows)

Packages Permissions
✅ write:packages (Upload packages to GitHub Package Registry)
✅ read:packages (Download packages from GitHub Package Registry)

Organization Permissions
✅ manage_runners:org (Manage org runners and runner groups)
```

</details>

## PREPARATION

<details><summary><b>CLONE REPO</b></summary>

```bash
git clone https://github.com/vre-charite-dev/vre-infra.git
cd vre-infra
```

<details><summary>OPTIONAL: CLONE BY TAG</summary>

```bash
# ONCE / IF THERE ARE TAGS YOU COULD SWITCH THAT WAY TO A RELEASED VERSION
git checkout tags/<tag-name>
```

</details>

<details><summary>OPTIONAL: CHECKOUT A SPECIFC HASH FROM COMMIT HISTORY</summary>

```bash
git checkout <commit-hash>
```

</details>

</details>

## CONFIGURATION

<details><summary>OPTION A: EDIT EXISTING CONFIGURATION FILE</summary>

```bash
# EDIT FILE / MAKE CHANGES e.g
vi ./terraform/config/charite/charite.tfvars
```

</details>

<details><summary>OPTION B: CREATE NEW ENVIORONMENT / CONFIGURATION FILE</summary>

```bash
ENV=production # just an example name
PATH_DEFAULT_CONFIG=./terraform/config/charite/charite.tfvars
PATH_NEW_CONFIG=./terraform/config/${ENV}/${ENV}.tfvars

# CREATE FOLDER FOR ENV
mkdir -p ./terraform/config/${ENV}/
cp ${PATH_DEFAULT_CONFIG} ${PATH_NEW_CONFIG}
# EDIT FILE / MAKE CHANGES e.g.
vi ${PATH_NEW_CONFIG}
```

</details>

## SECRETS

<details><summary>OPTION A: ADD SECRETS TO ENV</summary>

```bash
export TF_VAR_ghcr_token="${GITHUB_USERNAME}:${GITHUB_TOKEN}"
export TF_VAR_vault_token=""
export TF_VAR_kubeconfig=/path/to/kube/config
```

</details>

<details><summary>OPTION B: ADD NEEDED SECRETS TO A FILE (SECRETS.AUTO.TFVARS)</summary>

```bash
# CREATE THE SECRETS.AUTO.TFVARS FILE IN THE TERRAFORM FOLDERS
GITHUB_USERNAME="<CHANGE-ME>"
GITHUB_TOKEN="<CHANGE-ME>"
VAULT_TOKEN="<CHANGE-ME>"

FOLDERS=("pre-install" "install" "intermediary-install" "post-install")

for TF_FOLDER in "${FOLDERS[@]}"; do
  cat <<EOF > "./terraform/${TF_FOLDER}/secrets.auto.tfvars"
ghcr_token  = "${GITHUB_USERNAME}:${GITHUB_TOKEN}"
vault_token = "${VAULT_TOKEN}"
EOF

done
```

</details>

## DEPLOYMENT

<details><summary><b>OPTION A: APPLY VRE - ALL AT ONCE</b></summary>

```bash
PATH_CONFIG=./terraform/config/charite/charite.tfvars # or change to a newly created env config file
FOLDERS=("pre-install" "install" "intermediary-install" "post-install")
VAR_FILE=${PATH_CONFIG}

for TF_FOLDER in "${FOLDERS[@]}"; do
  terraform -chdir=./terraform/${TF_FOLDER} init
  terraform -chdir=./terraform/${TF_FOLDER} apply --auto-approve -var-file=${VAR_FILE}
done
```

</details>

<details><summary><b>OPTION B: APPLY VRE - ONE BY ONE</b></summary>

### 1. PRE-INSTALL

pre-install creates:
  * cert-manager, ingress, observability, etc.
  * multiple secrets for authentication (regcred and vault-secret across various namespaces)
  * two Helm releases (cert-manager and trust-manager)

<details><summary><b>Apply pre-install</b></summary>

```bash
cd ./terraform/pre-install
terraform init
terraform apply --auto-approve
```

</details>

<details><summary><b>Verify pre-install w/ kubectl+helm</b></summary>

```bash
export KUBECONFIG=/path/to/kube/config
# GENERAL
kubectl get namespaces
# EXAMPLE CHECKS
kubectl get namespace cert-manager ingress observability
kubectl get secret regcred -n cert-manager
kubectl describe secret regcred -n cert-manager
# GENERAL
helm list -A
# EXAMPLE CHECKS
helm status cert-manager -n cert-manager
helm status trust-manager -n cert-manager
kubectl get pods -n cert-manager
kubectl get pods -n ingress
kubectl get pods -n observability
```

</details>

### 2. INTERMEDIARY-INSTALL

intermediary-install creates:
  * cert-manager resources, including a self-signed issuer, a root certificate + cluster issuer
  * server certificates were generated for the operator and a MinIO tenant
  * jaeger operator

<details><summary><b>Apply intermediary-install</b></summary>

```bash
cd ./terraform/intermediary-install # or cd ../intermediary-install changing from previous apply operation
terraform init
terraform apply --auto-approve
```

</details>

<details><summary><b>Verify intermediary-install w/ kubectl+helm</b></summary>

```bash
# List all ClusterIssuers and Issuers
kubectl get clusterissuers,issuers -A
# Describe a specific ClusterIssuer
kubectl describe clusterissuer <issuer-name>
# List all Certificates
kubectl get certificates -A
# Describe a specific Certificate
kubectl describe certificate <certificate-name> -n <namespace>
# Check CertificateRequest status
kubectl get certificaterequests -A
# List Secrets to confirm certificates were created
kubectl get secrets -A | grep tls
# Inspect a specific TLS secret
kubectl describe secret <secret-name> -n <namespace>
# Check Helm releases
helm list -A | grep jaeger
# Get detailed status of Jaeger Operator Helm release
helm status jaeger -n <namespace>
# Check Jaeger Operator pods
kubectl get pods -n <namespace> | grep jaeger
# Describe Jaeger Operator deployment
kubectl describe deployment jaeger-operator -n <namespace>
# Check logs for troubleshooting
kubectl logs -l app.kubernetes.io/name=jaeger-operator -n <namespace>
```

</details>

### 3. INSTALL

install creates:

* Core Services: Kong, Redis, Elasticsearch, Neo4j, OpenLDAP, MinIO.
* Application Services: Approval, Encryption, Cataloguing, Dataset, Provenance, Notification, etc.
* Utility Services: Mailhog, Queue Consumer, Queue Producer, Pipeline Watch, etc.

<details><summary><b>Apply install</b></summary>

```bash
cd ./terraform/install # or cd ../install changing from previous apply operation
terraform init
terraform apply --auto-approve -var-file="../config/charite/charite.tfvars"
```

</details>

<details><summary><b>Verify install w/ kubectl+helm</b></summary>

```bash
# List All Helm Releases
helm list --all-namespaces
# Check Resources for a Specific Helm Release
helm status <release-name> -n <namespace>
# Example Commands for Specific Releases
helm status kong -n <namespace>
kubectl get pods -n <namespace> -l app.kubernetes.io/instance=kong
helm status redis -n <namespace>
kubectl get services -n <namespace> -l app.kubernetes.io/instance=redis
kubectl get configmaps -n <namespace> -l app.kubernetes.io/instance=<release-name>
kubectl get secrets -n <namespace> -l app.kubernetes.io/instance=<release-name>
kubectl get pv
kubectl get pvc -n <namespace>
```

</details>

### 4. POST-INSTALL

post-install creates:

* Atlas: ConfigMap and Job for Atlas configuration.
* Elasticsearch and Kong: ConfigMaps and Jobs for Elasticsearch and Kong setup.
* Keycloak:
  * A new realm (vre).
  * Multiple OpenID clients (react_app_client, minio_client, kong_client).
  * Roles (platform_admin, admin_role).
  * Protocol mappers for client configurations.
  * A user (admin_user) with assigned roles.
  * Service account roles and client default scopes.

<details><summary><b>Apply post-install</b></summary>

```bash
CONFIG_FILE="../config/charite/charite.tfvars" # example
cd ./terraform/post-install # or cd ../post-install changing from previous apply operation
terraform init
terraform apply --auto-approve -var-file="${CONFIG_FILE}
```

</details>

<details><summary><b>Verify post-install w/ kubectl+helm</b></summary>

```bash
# Check Atlas ConfigMap
kubectl get configmap atlas-custom-entity -n utility
# Check Elasticsearch ConfigMap
kubectl get configmap elasticsearch-index-configmap -n <namespace>
# Check Elasticsearch Job
kubectl get job elasticsearch-index-job -n <namespace>
# Check Kong ConfigMap
kubectl get configmap kong-configmap -n <namespace>
# Check Kong Job
kubectl get job kong-job -n <namespace>
# Check Atlas Job
kubectl get job atlas-config-job -n utility
# Verify Keycloak Realm (vre)
kubectl exec -it <keycloak-pod> -n <namespace> -- /opt/keycloak/bin/kcadm.sh get realms/vre
# Verify OpenID Clients
kubectl exec -it <keycloak-pod> -n <namespace> -- /opt/keycloak/bin/kcadm.sh get clients -r vre
# Verify Client Default Scopes
kubectl exec -it <keycloak-pod> -n <namespace> -- /opt/keycloak/bin/kcadm.sh get clients/<client-id>/default-client-scopes -r vre
```

</details>

</details>

### TROUBLESHOOTING TERRAFORM

<details><summary><b>Check Terraform Output</b></summary>

Terraform usually provides error messages when a run fails. Review the output:

```sh
terraform apply --auto-approve
```

To capture the output into a file for easier review:

```sh
terraform apply --auto-approve | tee terraform_output.log
```

</details>

<details><summary><b>Verify Environment Variables</b></summary>

```bash
echo $GITHUB_USERNAME
echo $GITHUB_TOKEN | sed 's/./*/g'  # Masked output for security
echo $VAULT_TOKEN | sed 's/./*/g'
```

Alternatively, use a .env file and source it:

```bash
source .env
```

</details>

<details><summary><b>Validate Terraform Configuration</b></summary>

Check for syntax or structural errors in the Terraform files:

```bash
terraform validate
```

If validation passes but apply still fails, check the execution plan:

```bash
terraform plan
```

</details>

<details><summary><b>Enable Debug Logging</b></summary>

For more details on the error, enable debug logging:

```bash
export TF_LOG=DEBUG
terraform apply --auto-approve 2>&1 | tee terraform_debug.log
```

</details>

<details><summary><b>Restart Terraform from Scratch</b></summary>

If troubleshooting doesn’t resolve the issue, reset Terraform and try again:

```bash
terraform destroy --auto-approve  # Destroy existing resources
rm -rf .terraform/ terraform.tfstate*  # Delete local state
terraform init
terraform apply --auto-approve
```

</details>


### UNINSTALL

<details><summary><b>OPTION A: DESTROY VRE - ALL AT ONCE</b></summary>

```bash
PATH_CONFIG=$(pwd)/terraform/config/charite/charite.tfvars # or change to a newly created env config file
FOLDERS=("post-install" "install" "intermediary-install" "pre-install")
VAR_FILE=${PATH_CONFIG}

for TF_FOLDER in "${FOLDERS[@]}"; do
  echo destroying ${TF_FOLDER}
  terraform -chdir=./terraform/${TF_FOLDER} destroy --auto-approve -var-file=${VAR_FILE}
  echo destroy ${TF_FOLDER} complete!
done
```

</details>

<details><summary><b>OPTION B: DESTROY SPECIFIC VRE DEPLOYMENT STEP</b></summary>

```bash
CONFIG_FILE="../config/charite/charite.tfvars" # example, needed for at least install & post-install steps
cd ./terraform/<INSTALL-NAME> # e.g. install or post-install
terraform destroy --auto-approve -var-file="${CONFIG_FILE}
```


</details>
