# vre-infra

Charite VRE Deployment repo for helm charts, config values, etc...

## current workflow:

- be sure to have the right kubeconfig loaded, default is `~/.kube/config`
- test your connection to the cluster `kubectl get pods -A`

---

## deploy into the cluster

* [DEPLOYMENT-GUIDE](DEPLOYMENT.md)

## to destoy current deployment

- switch into the terraform folder
- use terraform for deployment, see terraform documentation on how to this, basically it's
  - terraform destroy

## Coding Style

This is basically a terraform repository.
There are certain things such as formatting which terraform natively takes care of.
Please run `terraform validate` and `terraform fmt -recursive` before commiting code.
Currently, we don't do pipeline checks, but it's very likely we will add this in the future.
We don't do linting at this point, so please try to follow these [official recommendations](https://developer.hashicorp.com/terraform/language/style).

> Use underscores to separate multiple words in (resource) names.

## Vault

- added namespace for vault
- added helm_release for vault
- added values.yaml for fault
- disabled developer mode; enabled tls

> [!Tip]
> To unseal the vault after initial setup, connect to shell of the vault pod. Run `vault operator init` and save the
> listed unseal keys and the initial root token.
> To unseal the vault run `vault operator unseal` at least three times. Each time present another unseal key.
> You may need to append `-tls-skip-verify` after each command, since we are using a self-signed certificate.

## PKI - Cert-Manager et al.

We use a self-signed PKI to issue server certificates for the applications deployed to VRE (as of now).
In the following, we roughly depict the dependencies among the involved components and explain the consequences for the
deployment order.

As we rely on cert-manager for the certificate distribution and renewal, we have to install cert-manager first in the
cluster.
Basically, in order to make cert-manager's custom resource definition (crd)s available in the cluster as those need to
be present in the cluster for subsequent `terraform plan` steps to succeed that want to generate certificate resources
from those crds.

We use trust-manager to make the root certificate available to applications in the cluster such that those applications
can verify the presented server certificate up to the root.
All our server certificates are immediately issued from the root for the sake of simplicity.
Thus, client applications need to know / trust the root certificate otherwise the tls connection attempt to the server
fails.

Minio is such a candidate that needs that kind of trust establishment, for instance.
Operator and tenant communicate and the operator needs to trust the server certificate presented by the tenant.

Furthermore, minio's tenant and operator deployment require their respective server certificates to be present already
in the cluster at deployment time.

Other applications thus far follow standard procedures pretty much and are thus not discussed in detail.
The source code should suffice as documentation.

### Deployment order

Hence, cert-manager et al. have to be rolled-out in the following order:

1. **pre-installation**: cert-manager and trust-manager
2. **intermediary-installation**:
   1. the vre root certificate and the cluster issuer (issues new certificates derived from the root)
   2. minio server certificates for both tenant and operator
3. **installation:**:
   - minio tenant and operator
   - all other applications that rely on the pki to be fully installed in the cluster
