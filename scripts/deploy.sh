#!/bin/bash

# WordPress on AWS ECS Deployment Script
# This script helps deploy the WordPress infrastructure to AWS

set -e

echo "======================================"
echo "WordPress on AWS ECS Deployment"
echo "======================================"
echo ""

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed."
    echo "Please install Terraform from: https://www.terraform.io/downloads"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed."
    echo "Please install AWS CLI from: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured."
    echo "Please run: aws configure"
    exit 1
fi

echo "✓ AWS credentials configured"
echo ""

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found."
    echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it."
    echo ""
    echo "  cp terraform.tfvars.example terraform.tfvars"
    echo "  nano terraform.tfvars"
    echo ""
    exit 1
fi

echo "✓ Configuration file found"
echo ""

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

echo ""
echo "======================================"
echo "Deployment Plan"
echo "======================================"
echo ""

# Show plan
terraform plan

echo ""
echo "======================================"
read -p "Do you want to proceed with deployment? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Apply
echo "Deploying infrastructure..."
terraform apply -auto-approve

echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""

# Show outputs
terraform output

echo ""
echo "Next steps:"
echo "1. Wait 5-10 minutes for all services to be fully running"
echo "2. Visit your WordPress site at the URL shown above"
echo "3. Complete the WordPress installation wizard"
echo ""
