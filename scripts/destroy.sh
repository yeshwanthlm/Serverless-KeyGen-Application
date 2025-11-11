#!/bin/bash
set -e

echo "=========================================="
echo "Destroying Serverless Key Generator"
echo "=========================================="
echo ""

read -p "Are you sure you want to destroy all resources? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Destroying infrastructure..."
cd terraform
terraform destroy

echo ""
echo "✓ All resources destroyed"
