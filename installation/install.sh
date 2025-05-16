#!/bin/bash

REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
dirs=(
  "job-publisher"
  "consumer"
  "scaler"
  "service-monitor"
  "ingresses"
)

chmod +x setup_tools.sh
chmod +x create_cluster.sh
chmod +x coredns.sh

./setup_tools.sh
./create_cluster.sh
./coredns.sh

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
helm install loki grafana/loki-stack --namespace monitoring --set promtail.enabled=true --set grafana.enabled=false --set loki.image.tag=2.9.3

kubectl create namespace lavinmq

for dir in "${dirs[@]}"; do
  echo "Applying manifests from $REPO_ROOT_DIR/$dir"
  kubectl apply -f "$REPO_ROOT_DIR/$dir"
done




