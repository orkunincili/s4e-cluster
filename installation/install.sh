#!/bin/bash

REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
chmod +x setup_tools.sh
chmod +x create_cluster.sh
chmod +x coredns.sh

./setup_tools.sh
./create_cluster.sh
./coredns.sh

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

kubectl create namespace lavinmq
kubectl create namespace efk
cd $REPO_ROOT_DIR/job-publisher
kubectl apply -f .

cd $REPO_ROOT_DIR/consumer
kubectl apply -f .

cd $REPO_ROOT_DIR/scaler
kubectl apply -f .

cd $REPO_ROOT_DIR/service-monitor
kubectl apply -f .

cd $REPO_ROOT_DIR/efk
kubectl apply -f .
