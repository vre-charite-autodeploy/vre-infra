# KIND

## DEPLOY CNI/CILIUM

```bash
cat <<EOF > ./cilium-values.yaml
kubeProxyReplacement: true
routingMode: "native"
ipv4NativeRoutingCIDR: "10.244.0.0/16"
k8sServiceHost: "vre-vanilla-control-plane"
k8sServicePort: 6443

l2announcements:
  enabled: true
  leaseDuration: "3s"
  leaseRenewDeadline: "1s"
  leaseRetryPeriod: "500ms"

devices: ["eth0", "net0"]

externalIPs:
  enabled: true

autoDirectNodeRoutes: true

operator:
  replicas: 2
EOF

export KUBECONFIG=~/.kube/kind-vre-vanilla

helm repo add cilium https://helm.cilium.io/ && helm repo update

helm upgrade --install cilium cilium/cilium \
--namespace kube-system \
--version 1.17.1 \
--values cilium-values.yaml

kubectl wait \
--for=condition=Ready pods --all \
--namespace kube-system \
--timeout 240s
```

## CONFIGURE LOADBALANCING

```bash
cat <<EOF > ./cilium-lb-config.yaml
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: ip-pool
spec:
  blocks:
    - start: 172.18.250.0
      stop: 172.18.250.50
---
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: default-l2-announcement-policy
  namespace: kube-system
spec:
  externalIPs: false
  loadBalancerIPs: true
  interfaces:
    - ^eth[0-9]+
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: DoesNotExist
EOF

export KUBECONFIG=~/.kube/kind-vre-vanilla
kubectl apply -f ./cilium-lb-config.yaml
```
