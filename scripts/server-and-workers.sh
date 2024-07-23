#!/bin/bash

PRIVATE_KEY_PATH="C:/Users/andre/.ssh/node.priv.pem"
KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
SSH_KEY_PATH="$HOME/.ssh/test123"

convert_ip_to_node_name() {
    local ip=$1
    echo "ip-${ip//./-}"
}

# Get ssh key
aws ssm get-parameter --name " /LAPALMA/US_EAST_1/SERVER_HOST/PRIVATE_KEY" --with-decryption --region us-east-1 --query "Parameter.Value" --output text > "$PRIVATE_KEY_PATH"

# Start server
SERVER_PUBLIC_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=lapalma-prod-server" --query "Reservations[*].Instances[*].PublicIpAddress" --region us-east-1 --output text)
SERVER_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=lapalma-prod-server" --query "Reservations[*].Instances[*].PrivateIpAddress" --region us-east-1 --output text)
INITIATE_SERVER="sudo ufw disable && curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --resolv-conf /run/systemd/resolve/resolv.conf --flannel-backend=host-gw"
ssh -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" ubuntu@"$SERVER_PUBLIC_IP" "$INITIATE_SERVER"

# Add Github ssh key
scp -i "$PRIVATE_KEY_PATH" $SSH_KEY_PATH ubuntu@"$SERVER_PUBLIC_IP":~/.ssh/id_rsa

# Extract K3s token from the server
TOKEN=$(ssh -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" ubuntu@"$SERVER_PUBLIC_IP" "sudo cat /var/lib/rancher/k3s/server/node-token")

# Connect node workers
INITIATE_NODES="curl -sfL https://get.k3s.io | K3S_URL=https://$SERVER_PUBLIC_IP:6443 sh -s - agent --token $TOKEN"
WORKER_PUBLIC_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=lapalma-prod-node" --query "Reservations[*].Instances[*].PublicIpAddress" --region us-east-1 --output text)
WORKER_PRIVATE_IPS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=lapalma-prod-node" --query "Reservations[*].Instances[*].PrivateIpAddress" --region us-east-1 --output text)

for WORKER_IP in $WORKER_PUBLIC_IPS; do
    # Remove whitespaces
    WORKER_IP=$(echo "$WORKER_IP" | xargs)

    echo "Connecting to $WORKER_IP"
    ssh -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" ubuntu@"$WORKER_IP" "$INITIATE_NODES"
done

ssh -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" ubuntu@"$SERVER_PUBLIC_IP" << EOF
    WORKER_PRIVATE_IPS="$WORKER_PRIVATE_IPS" 

    sleep 10
    
    chmod 700 ~/.ssh
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
    chmod 600 ~/.ssh/id_rsa

    # Point kubeconfig
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown \$(id -u):\$(id -g) ~/.kube/config
    sudo chown -R \$(id -u):\$(id -g) \$HOME/.kube/

    # Install helm
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh

    WORKER_IP=\$(echo "$SERVER_PRIVATE_IP" | tr -d '\r' | xargs)
    WORKER_IP=\$(echo "\$WORKER_IP" | xargs)
    WORKER_IP=\$(echo ip-\$WORKER_IP | tr '.' '-')
    sudo k3s kubectl label nodes "\$WORKER_IP" NodeType=apps 

    # Label the worker nodes
    for WORKER_IP in \$WORKER_PRIVATE_IPS; do
        WORKER_IP=\$(echo "\$WORKER_IP" | tr -d '\r' | xargs)
        WORKER_IP=\$(echo "\$WORKER_IP" | xargs)
        NODE_NAME=\$(echo ip-\$WORKER_IP | tr '.' '-')
        sudo k3s kubectl label nodes "\$NODE_NAME" NodeType=apps
        sudo k3s kubectl label nodes "\$NODE_NAME" kubernetes.io/role=worker
    done
EOF