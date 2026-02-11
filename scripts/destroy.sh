#!/bin/bash

# WordPress on AWS ECS Destruction Script
# This script helps destroy the WordPress infrastructure from AWS

set -e

echo "======================================"
echo "WordPress on AWS ECS Destruction"
echo "======================================"
echo ""
echo "WARNING: This will destroy all resources!"
echo "Make sure you have backed up your WordPress data and database."
echo ""

read -p "Are you sure you want to destroy all resources? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "Destruction cancelled."
    exit 0
fi

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Destroy
echo "Destroying infrastructure..."
terraform destroy

echo ""
echo "======================================"
echo "Destruction Complete!"
echo "======================================"
echo ""
