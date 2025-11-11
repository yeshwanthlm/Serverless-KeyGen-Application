#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "=========================================="
echo "Serverless Key Generator Deployment"
echo "=========================================="
echo ""
echo "Project root: $PROJECT_ROOT"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
command -v aws >/dev/null 2>&1 || { echo "Error: AWS CLI not found"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Error: Terraform not found"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Error: Docker not found"; exit 1; }

echo "✓ All prerequisites met"
echo ""

# Check AWS credentials
echo "Verifying AWS credentials..."
aws sts get-caller-identity >/dev/null 2>&1 || { echo "Error: AWS credentials not configured"; exit 1; }
echo "✓ AWS credentials valid"
echo ""

# Check Docker is running
echo "Checking Docker..."
docker ps >/dev/null 2>&1 || { echo "Error: Docker is not running"; exit 1; }
echo "✓ Docker is running"
echo ""

# Step 1: Initialize Terraform
echo "Step 1: Initializing Terraform..."
cd "$PROJECT_ROOT/terraform"
terraform init
echo ""

# Step 2: Create base infrastructure (ECR, SQS, DynamoDB)
echo "Step 2: Creating base infrastructure (ECR, SQS, DynamoDB)..."
terraform apply -target=module.infrastructure -auto-approve
echo ""

# Step 3: Build and push Docker image
echo "Step 3: Building and pushing Docker image to ECR..."
cd "$PROJECT_ROOT"
bash scripts/build-and-push.sh
echo ""

# Step 4: Deploy remaining infrastructure (Lambda, API Gateway, S3)
echo "Step 4: Deploying Lambda functions, API Gateway, and Web App..."
cd "$PROJECT_ROOT/terraform"
terraform apply -auto-approve
echo ""

# Display outputs
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
terraform output
echo ""
echo "Test your API:"
echo "  curl -X POST \$(terraform output -raw api_endpoint)/keygen -H 'Content-Type: application/json' -d '{\"key_type\":\"ed25519\"}'"
echo ""
echo "Open web interface:"
echo "  open \$(terraform output -raw webapp_url)"
