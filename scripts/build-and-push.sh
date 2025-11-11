#!/bin/bash
set -e

echo "Building and pushing Lambda container image to ECR..."

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")

# ECR repository details
ECR_REPO="keygen-processor"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

echo "AWS Account: ${AWS_ACCOUNT_ID}"
echo "Region: ${AWS_REGION}"
echo "ECR Repository: ${ECR_URI}"

# Authenticate Docker to ECR
echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build Docker image
echo "Building Docker image..."
cd lambda/processor
docker build --platform linux/amd64 -t ${ECR_REPO}:latest .

# Tag image
echo "Tagging image..."
docker tag ${ECR_REPO}:latest ${ECR_URI}:latest

# Push to ECR
echo "Pushing image to ECR..."
docker push ${ECR_URI}:latest

echo "✓ Image successfully pushed to ${ECR_URI}:latest"
echo ""
echo "You can now run 'terraform apply' to deploy the Lambda function."
