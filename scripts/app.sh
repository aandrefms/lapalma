#!/bin/bash

PRIVATE_KEY_PATH="~/.ssh/node.priv.pem"
SERVER_PUBLIC_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=lapalma-prod-server" --query "Reservations[*].Instances[*].PublicIpAddress" --region us-east-1 --output text)
TEMP_FILE_NAME="application.tar.gz"

# Zip yamls
tar -czvf "$TEMP_FILE_NAME" -C ./application .
scp -i "$PRIVATE_KEY_PATH" "$TEMP_FILE_NAME" ubuntu@"$SERVER_PUBLIC_IP":/home/ubuntu/
rm "$TEMP_FILE_NAME"

ssh -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" ubuntu@"$SERVER_PUBLIC_IP" << EOF
    mkdir ./application && tar -xzvf application.tar.gz -C ./application

    cd ./yamls
    kubectl apply -f ./consumer.yaml,./server.yaml,./health_alert.yaml
EOF
