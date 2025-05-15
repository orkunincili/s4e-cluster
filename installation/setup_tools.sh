#!/bin/bash

REPO_ROOT_DIR=$(git rev-parse --show-toplevel)

# 1) Multipass installation
echo "Installing Multipass..."
if ! command -v multipass &> /dev/null; then
    echo "Multipass is not installed, installing..."
    sudo snap install multipass
    if [ $? -ne 0 ]; then
        echo "Multipass installation failed. Exiting..."
        exit 1
    fi
else
    echo "Multipass is already installed."
fi

# 2) kubectl installation
echo "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed, installing..."
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    if [ $? -ne 0 ]; then
        echo "kubectl installation failed. Exiting..."
        exit 1
    fi
else
    echo "kubectl is already installed."
fi


echo "Installing KubeSpray..."
if [ ! -d "kubespray" ]; then
    echo "Cloning KubeSpray repository..."
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray/
    git checkout release-2.24
    sudo apt update
    sudo apt install -y python3-pip
    pip3 install -r requirements.txt
    cd ..
    if [ $? -ne 0 ]; then
        echo "KubeSpray repository cloning failed. Exiting..."
        exit 1
    fi
else
    echo "KubeSpray is already present."
fi

echo "KubeSpray installation completed."

# 4) Helm installation
echo "Installing Helm..."
if ! command -v helm &> /dev/null; then
    echo "Helm is not installed, installing..."
    
    # Download the latest Helm version
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    if [ $? -ne 0 ]; then
        echo "Helm installation failed. Exiting..."
        exit 1
    fi
else
    echo "Helm is already installed."
fi

echo "Helm installation completed."

