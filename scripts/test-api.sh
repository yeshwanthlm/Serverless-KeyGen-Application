#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Get API endpoint from Terraform output
cd "$PROJECT_ROOT/terraform"
API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null)

if [ -z "$API_ENDPOINT" ]; then
    echo "Error: Could not get API endpoint. Has the infrastructure been deployed?"
    exit 1
fi

echo "Testing Serverless Key Generator API"
echo "API Endpoint: $API_ENDPOINT"
echo ""

# Test 1: Generate RSA key
echo "Test 1: Generating RSA 2048-bit key..."
RESPONSE=$(curl -s -X POST "$API_ENDPOINT/keygen" \
    -H "Content-Type: application/json" \
    -d '{"key_type":"rsa","key_bits":2048}')

REQUEST_ID=$(echo $RESPONSE | jq -r '.request_id')
echo "Request ID: $REQUEST_ID"
echo "Status: $(echo $RESPONSE | jq -r '.status')"
echo ""

# Wait for processing
echo "Waiting for key generation..."
sleep 5

# Fetch result
echo "Fetching result..."
RESULT=$(curl -s "$API_ENDPOINT/result/$REQUEST_ID")
STATUS=$(echo $RESULT | jq -r '.status')

if [ "$STATUS" == "complete" ]; then
    echo "✓ Key generated successfully!"
    echo "Key Type: $(echo $RESULT | jq -r '.key_type')"
    echo "Key Bits: $(echo $RESULT | jq -r '.key_bits')"
    echo "Fingerprint: $(echo $RESULT | jq -r '.fingerprint')"
    echo ""
    echo "Public Key (first 80 chars):"
    echo $RESULT | jq -r '.public_key_b64' | base64 -d | head -c 80
    echo "..."
else
    echo "Status: $STATUS"
    echo "Full response:"
    echo $RESULT | jq
fi

echo ""
echo ""

# Test 2: Generate Ed25519 key
echo "Test 2: Generating Ed25519 key..."
RESPONSE=$(curl -s -X POST "$API_ENDPOINT/keygen" \
    -H "Content-Type: application/json" \
    -d '{"key_type":"ed25519"}')

REQUEST_ID=$(echo $RESPONSE | jq -r '.request_id')
echo "Request ID: $REQUEST_ID"
echo ""

sleep 5

RESULT=$(curl -s "$API_ENDPOINT/result/$REQUEST_ID")
STATUS=$(echo $RESULT | jq -r '.status')

if [ "$STATUS" == "complete" ]; then
    echo "✓ Ed25519 key generated successfully!"
    echo "Fingerprint: $(echo $RESULT | jq -r '.fingerprint')"
else
    echo "Status: $STATUS"
fi

echo ""
echo "All tests completed!"
