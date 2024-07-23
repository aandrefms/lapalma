#!/bin/bash
PRIVATE_KEY_PATH="~/.ssh/node.priv.pem"
SERVER_PUBLIC_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=lapalma-prod-server" --query "Reservations[*].Instances[*].PublicIpAddress" --region us-east-1 --output text)
TEMP_FILE_NAME="yamls.tar.gz"

# Grafana ALB
LOAD_BALANCER_ARN=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=grafana-alb --resource-type-filters "elasticloadbalancing:loadbalancer" --query "ResourceTagMappingList[*].ResourceARN" --output text --region us-east-1)
DNS_NAME_GRAFANA=$(aws elbv2 describe-load-balancers --load-balancer-arns $LOAD_BALANCER_ARN --query "LoadBalancers[*].DNSName" --output text --region us-east-1)

sed -i "s/PLACEHOLDER/$DNS_NAME_GRAFANA/g" ./yamls/grafana.yaml

# Application ALB
LOAD_BALANCER_ARN=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=application-alb --resource-type-filters "elasticloadbalancing:loadbalancer" --query "ResourceTagMappingList[*].ResourceARN" --output text --region us-east-1)
DNS_NAME_APP=$(aws elbv2 describe-load-balancers --load-balancer-arns $LOAD_BALANCER_ARN --query "LoadBalancers[*].DNSName" --output text --region us-east-1)

# Change placeholder
sed -i "s/PLACEHOLDER/$DNS_NAME_APP/g" ./yamls/server.yaml

# Zip yamls
tar -czvf "$TEMP_FILE_NAME" -C ./yamls .
scp -i "$PRIVATE_KEY_PATH" "$TEMP_FILE_NAME" ubuntu@"$SERVER_PUBLIC_IP":/home/ubuntu/
rm "$TEMP_FILE_NAME"

# # Install monitoring environment
ssh -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" ubuntu@"$SERVER_PUBLIC_IP" << EOF

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add botkube 'https://charts.botkube.io'
    helm repo update

    mkdir ./yamls && tar -xzvf yamls.tar.gz -C ./yamls
    cd yamls

    # Install grafana
    sudo k3s kubectl apply -f ./namespaces,./grafana.yaml

    # Install metrics-server
    sudo k3s kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

    # Install prometheus
    helm upgrade --values ./prometheus.yaml -n monitoring  --install prometheus prometheus-community/kube-prometheus-stack --version v55.4.1

    # Install loki
    # helm upgrade --values ./loki.yaml --install loki-distributed grafana/loki-distributed -n monitoring
    helm upgrade --install loki --namespace=monitoring grafana/loki-stack

    # Install promtail
    # helm upgrade --values promtail.yaml --install promtail grafana/promtail -n monitoring

    # Install Botkube
    helm upgrade --values ./botkube.yaml --install botkube botkube/botkube -n monitoring --version v1.1.1

EOF

# Change placeholder
sed -i "s/$DNS_NAME_APP/PLACEHOLDER/g" ./yamls/server.yaml
sed -i "s/$DNS_NAME_GRAFANA/PLACEHOLDER/g" ./yamls/grafana.yaml