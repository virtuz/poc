#!/bin/bash

# WordPress Update Script
# This script forces a new deployment to update WordPress containers

set -e

echo "======================================"
echo "WordPress Container Update"
echo "======================================"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed."
    exit 1
fi

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Get cluster and service names from Terraform outputs
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "wordpress-ecs-cluster")
SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "wordpress-ecs-service")
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo "Region: $REGION"
echo ""

echo "Forcing new deployment..."
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$SERVICE_NAME" \
    --force-new-deployment \
    --region "$REGION"

echo ""
echo "✓ New deployment initiated"
echo "The ECS service will pull the latest WordPress image and restart tasks."
echo ""
