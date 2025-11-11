#!/bin/bash
set -e

echo "=========================================="
echo "Serverless Key Generator Deployment"
echo "=========================================="
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
cd terraform
terraform init
echo ""

# Step 2: Deploy everything (Terraform will build Docker image automatically)
echo "Step 2: Deploying infrastructure..."
echo "Note: This will build and push the Docker image automatically"
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
