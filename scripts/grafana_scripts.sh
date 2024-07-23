#!/bin/bash

LOAD_BALANCER_ARN=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=grafana-alb --resource-type-filters "elasticloadbalancing:loadbalancer" --query "ResourceTagMappingList[*].ResourceARN" --output text --region us-east-1)
DNS_NAME=$(aws elbv2 describe-load-balancers --load-balancer-arns $LOAD_BALANCER_ARN --query "LoadBalancers[*].DNSName" --output text --region us-east-1)

response=$(curl -X POST -H "Content-Type: application/json" -d '{"name":"general-key2","role":"Admin"}' http://admin:admin@"$DNS_NAME"/api/auth/keys)
key=$(echo $response | sed -n 's/.*"key":"\([^"]*\)".*/\1/p')
echo $key

# Create prometheus connection
curl -X POST -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $key" -d '{"name":"prometheus","type":"prometheus","url":"http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090","access":"proxy","basicAuth":false, "uid": "ab3cd928-91e5-4858-ac71-ff90a0229090"}' http://"$DNS_NAME"/api/datasources

# Create loki connection
curl -X POST -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $key" -d '{"name":"loki","type":"loki","url":"http://loki.monitoring:3100","access":"proxy","basicAuth":false, "uid": "d4f8dbd4-c1eb-4580-9dc5-2fad496ce58b"}' http://"$DNS_NAME"/api/datasources

# Create pod resources
curl -X POST -i "http://$DNS_NAME/api/dashboards/import" \
--data-binary @./grafana_dashs/resources.json \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "Authorization: Bearer $key"

# Create node resources
curl -X POST -i "http://$DNS_NAME/api/dashboards/import" \
--data-binary @./grafana_dashs/nodes.json \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "Authorization: Bearer $key"

# Create pod health monitoring
curl -X POST -i "http://$DNS_NAME/api/dashboards/import" \
--data-binary @./grafana_dashs/microservices.json \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "Authorization: Bearer $key"

# Create global monitoring
curl -X POST -i "http://$DNS_NAME/api/dashboards/import" \
--data-binary @./grafana_dashs/global.json \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "Authorization: Bearer $key"

# Create pods monitoring
curl -X POST -i "http://$DNS_NAME/api/dashboards/import" \
--data-binary @./grafana_dashs/pods.json \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "Authorization: Bearer $key"