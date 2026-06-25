#!/bin/bash

set -e

CLUSTER_NAME="localhelp"

echo "======================================"
echo " LocalHelp K3s Cluster Setup Starting "
echo "======================================"

sudo apt update -y
sudo apt upgrade -y

echo "Installing utilities..."
sudo apt install -y curl wget unzip jq net-tools

echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER

echo "Installing K3s..."

curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="\
--write-kubeconfig-mode=644 \
--node-name=${CLUSTER_NAME}-master" \
sh -

echo "Waiting for cluster..."
sleep 30

mkdir -p $HOME/.kube

sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config

if ! grep -q KUBECONFIG ~/.bashrc; then
  echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
fi

if ! grep -q "alias k=" ~/.bashrc; then
  echo "alias k='kubectl'" >> ~/.bashrc
fi

echo "======================================"
echo " Cluster Verification"
echo "======================================"

kubectl get nodes

echo "======================================"
echo " Creating Practice Namespace"
echo "======================================"

kubectl create namespace localhelp --dry-run=client -o yaml | kubectl apply -f -

echo "======================================"
echo " Deploying Nginx"
echo "======================================"

kubectl create deployment nginx \
  --image=nginx \
  -n localhelp \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl expose deployment nginx \
  --type=NodePort \
  --port=80 \
  -n localhelp

echo "======================================"
echo " Resources"
echo "======================================"

kubectl get nodes
kubectl get ns
kubectl get deploy -A
kubectl get pods -A
kubectl get svc -A

echo ""
echo "======================================"
echo " LocalHelp Cluster Ready"
echo "======================================"
echo ""
echo "Useful Commands:"
echo "kubectl get nodes"
echo "kubectl get pods -A"
echo "kubectl get svc -A"
echo "kubectl get deploy -A"
echo ""
echo "Namespace:"
echo "localhelp"
echo ""