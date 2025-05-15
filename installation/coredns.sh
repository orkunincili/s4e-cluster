#!/bin/bash

NAMESPACE="kube-system"
CONFIGMAP_NAME="coredns"

echo "[INFO] Patching CoreDNS ConfigMap..."

kubectl -n $NAMESPACE get configmap $CONFIGMAP_NAME -o yaml > coredns-original.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: $CONFIGMAP_NAME
  namespace: $NAMESPACE
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        cache 30
        reload
        loadbalance
    }
EOF

echo "[INFO] Restarting CoreDNS pods..."

kubectl -n $NAMESPACE rollout restart deployment coredns

echo "[DONE] CoreDNS ConfigMap updated and pods restarted."

