#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

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
echo "Step 1: Cleaning up ECR images..."
AWS_REGION=$(aws configure get region || echo "us-east-1")
ECR_REPO="keygen-processor"

# Check if repository exists and delete all images
if aws ecr describe-repositories --repository-names $ECR_REPO --region $AWS_REGION >/dev/null 2>&1; then
    echo "Deleting all images from ECR repository..."
    IMAGE_IDS=$(aws ecr list-images --repository-name $ECR_REPO --region $AWS_REGION --query 'imageIds[*]' --output json)
    
    if [ "$IMAGE_IDS" != "[]" ]; then
        aws ecr batch-delete-image \
            --repository-name $ECR_REPO \
            --region $AWS_REGION \
            --image-ids "$IMAGE_IDS" >/dev/null 2>&1 || echo "No images to delete"
        echo "✓ ECR images deleted"
    else
        echo "✓ No images found in ECR"
    fi
else
    echo "✓ ECR repository doesn't exist or already deleted"
fi

echo ""
echo "Step 2: Destroying infrastructure with Terraform..."
cd "$PROJECT_ROOT/terraform"
terraform destroy -auto-approve

echo ""
echo "✓ All resources destroyed"
