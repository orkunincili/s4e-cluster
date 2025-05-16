#!/bin/bash
REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
# Generate an SSH key pair
echo "Generating new SSH key pair..."
PUBLIC_KEY=$(ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -y)


echo "Creating cloud-init file..."
cat <<EOF > cloud-init.yaml
#cloud-config
ssh_authorized_keys:
  - $PUBLIC_KEY
EOF
# Step 1: Create VMs using multipass
echo "Creating master node..."
multipass launch --name master --cpus 1 --mem 2G --disk 10G --cloud-init cloud-init.yaml 

echo "Creating worker01 node..."
multipass launch --name worker01 --cpus 2 --mem 3G --disk 30G --cloud-init cloud-init.yaml

echo "Creating worker02 node..."
multipass launch --name worker02 --cpus 2 --mem 3G --disk 300G --cloud-init cloud-init.yaml

# Step 2: Wait for VMs to be "Ready"
echo "Waiting for VMs to initialize..."

# Function to check if the VM is ready
check_vm_ready() {
    vm_name=$1
    status=""
    while [[ "$status" != "Running" ]]; do
	echo "$vm_name is not Running yet. Waiting..."
        status=$(multipass info $vm_name | grep "State" | awk '{print $2}')
        if [[ "$status" == "Stopped" ]]; then
            # If VM is stopped, print error and exit
            echo "$vm_name is stopped! Exiting..."
            exit 1
        fi
    done
    echo "$vm_name is Ready now."
}

# Check each VM's readiness
check_vm_ready "master"
check_vm_ready "worker01"
check_vm_ready "worker02"

# Step 3: Get the IPs of the nodes
echo "Fetching IP addresses for the VMs..."

MASTER_IP=$(multipass info master | grep "IPv4" | awk '{print $2}')
WORKER01_IP=$(multipass info worker01 | grep "IPv4" | awk '{print $2}')
WORKER02_IP=$(multipass info worker02 | grep "IPv4" | awk '{print $2}')

# Step 4: Display the IPs
echo "Master IP: $MASTER_IP"
echo "Worker01 IP: $WORKER01_IP"
echo "Worker02 IP: $WORKER02_IP"
echo "Done."
# Step 5: Create cluster with Kubespray
echo "Creating K8s cluster..."
echo "Setting IP's to hosts.yaml"

sed -i "s/MASTER_IP/${MASTER_IP}/g" kubespray-config/hosts.yaml
sed -i "s/WORKER01_IP/${WORKER01_IP}/g" kubespray-config/hosts.yaml
sed -i "s/WORKER02_IP/${WORKER02_IP}/g" kubespray-config/hosts.yaml

HOSTS_LINE="$MASTER_IP grafana.local prometheus.local lavinmq.local kibana.local elastic.local"
HOSTS_FILE="/etc/hosts"

if ! grep -Fxq "$HOSTS_LINE" $HOSTS_FILE; then
  echo "$HOSTS_LINE" | sudo tee -a $HOSTS_FILE > /dev/null
fi
multipass exec worker01 -- sudo mkdir -p /mnt/data/lavinmq
multipass exec worker02 -- sudo mkdir -p /mnt/data/lavinmq

cd kubespray

cp -r inventory/sample inventory/s4ecluster
cp $REPO_ROOT_DIR/installation/kubespray-config/hosts.yaml inventory/s4ecluster
cp $REPO_ROOT_DIR/installation/kubespray-config/k8s-cluster.yml inventory/s4ecluster/group_vars/k8s_cluster
cp $REPO_ROOT_DIR/installation/kubespray-config/all.yml inventory/s4ecluster/group_vars/all
ansible-playbook -i inventory/s4ecluster/hosts.yaml --become --become-user=root cluster.yml
multipass exec master -- sudo cp /etc/kubernetes/admin.conf /home/ubuntu/admin.conf
multipass exec master -- sudo chown ubuntu:ubuntu /home/ubuntu/admin.conf
multipass transfer master:/home/ubuntu/admin.conf ./admin.conf
multipass exec master -- rm /home/ubuntu/admin.conf
sed -i "s|https://127.0.0.1:6443|https://$MASTER_IP:6443|g" admin.conf
mkdir -p ~/.kube
cp admin.conf ~/.kube/config
rm -rf admin.conf
cp $REPO_ROOT_DIR/kubespray-config/hosts.template $REPO_ROOT_DIR/kubespray-config/hosts.yaml

