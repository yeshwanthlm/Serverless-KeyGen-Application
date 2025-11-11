# Serverless Key Generator

<img width="946" height="848" alt="Screenshot 2025-11-11 at 7 27 06 PM" src="https://github.com/user-attachments/assets/046d75bc-7909-42d1-be81-dc3c61713f4d" />

A fully serverless SSH and API key generation service built on AWS using Terraform. Generate RSA, Ed25519, and ECDSA keys on-demand with automatic expiration.

## Architecture

```
Client → API Gateway → Lambda (Submit) → SQS Queue → Lambda (Processor) → DynamoDB
                                                                              ↓
Client ← API Gateway ← Lambda (Fetch) ←──────────────────────────────────────┘
```

## Features

- **Multiple Key Types**: RSA (2048/4096), Ed25519, ECDSA (P-256/P-384)
- **Asynchronous Processing**: Queue-based with SQS
- **Auto-Expiration**: Keys deleted after 24 hours (DynamoDB TTL)
- **Secure**: Keys generated in-memory, never written to disk
- **Web Interface**: Simple UI for testing
- **Cost-Effective**: ~$0.40/month for 10,000 keys

## Prerequisites

- AWS Account
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured
- [Docker](https://docs.docker.com/engine/install) running

## Project Structure

```
serverless-keygen/
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Root module orchestration
│   ├── variables.tf               # Global variables
│   ├── outputs.tf                 # Deployment outputs
│   ├── infrastructure/            # Core AWS resources
│   │   ├── main.tf               # SQS, DynamoDB, ECR
│   │   └── outputs.tf
│   ├── lambda/                    # Lambda functions
│   │   ├── main.tf               # Function definitions & IAM
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── api/                       # API Gateway
│   │   ├── main.tf               # HTTP API & routes
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── webapp/                    # Static website
│       ├── main.tf               # S3 bucket & hosting
│       ├── variables.tf
│       └── outputs.tf
├── lambda/                         # Lambda function code
│   ├── submit/
│   │   └── handler.py            # POST /keygen handler
│   ├── fetch/
│   │   └── handler.py            # GET /result/{id} handler
│   └── processor/                 # Container-based processor
│       ├── handler.py            # Key generation logic
│       ├── Dockerfile            # Container definition
│       └── requirements.txt      # Python dependencies
├── webapp/
│   └── index.html                 # Web interface
├── scripts/                        # Deployment automation
│   ├── deploy.sh                 # Full deployment
│   ├── build-and-push.sh         # Docker build & ECR push
│   ├── destroy.sh                # Cleanup resources
│   └── test-api.sh               # API testing
├── README.md                       # This file
├── ARCHITECTURE.md                 # System design details
├── DEPLOYMENT.md                   # Deployment guide
├── EXAMPLES.md                     # Usage examples
├── UNLICENSE                       # Public domain license
└── .gitignore
```

## Quick Start

### 1. Configure AWS

```bash
aws configure
```

### 2. Start Docker

Make sure Docker Desktop is running:
```bash
docker ps  # Should not error
```

### 3. Deploy

```bash
# Build and push Docker image
./scripts/deploy.sh
```

### 4. Test

```bash
# Get API endpoint
API=$(terraform output -raw api_endpoint)

# Generate a key
curl -X POST "$API/keygen" \
  -H "Content-Type: application/json" \
  -d '{"key_type":"ed25519"}' | jq

# Open web interface
open $(terraform output -raw webapp_url)
```

## API Reference

### POST /keygen

```bash
curl -X POST "$API/keygen" \
  -H "Content-Type: application/json" \
  -d '{"key_type":"rsa","key_bits":2048}'
```

**Parameters:**
- `key_type`: `rsa`, `ed25519`, or `ecdsa` (default: `rsa`)
- `key_bits`: `2048` or `4096` for RSA (default: `2048`)
- `curve`: `P-256` or `P-384` for ECDSA (default: `P-256`)

**Response:**
```json
{"request_id": "550e8400-...", "status": "queued"}
```

### GET /result/{request_id}

```bash
curl "$API/result/550e8400-..."
```

**Response:**
```json
{
  "request_id": "550e8400-...",
  "status": "complete",
  "key_type": "rsa",
  "public_key_b64": "...",
  "private_key_b64": "...",
  "fingerprint": "SHA256:...",
  "generated_at": "2025-11-11T10:30:00Z"
}
```

## Configuration

Edit `terraform/variables.tf`:

```hcl
variable "aws_region" {
  default = "us-east-1"  # Change region
}

variable "key_ttl_seconds" {
  default = 86400  # 24 hours (change to 604800 for 7 days)
}
```

## Security

- Keys generated in-memory only
- Automatic expiration after 24 hours
- IAM least-privilege roles
- HTTPS-only API access
- No persistent key storage

**For Production:**
- Add API authentication (API keys/IAM)
- Enable KMS encryption for DynamoDB
- Restrict CORS origins
- Add rate limiting with AWS WAF

## Cost

~$0.40/month for 10,000 keys (after free tier)

## Monitoring

```bash
# View logs
aws logs tail /aws/lambda/keygen-processor --follow
aws logs tail /aws/lambda/keygen-submit --follow
```

## Troubleshooting

**Keys not generating?**
```bash
# Check SQS queue
aws sqs get-queue-attributes \
  --queue-url $(cd terraform && terraform output -raw sqs_queue_url) \
  --attribute-names ApproximateNumberOfMessages

# Check logs
aws logs tail /aws/lambda/keygen-processor --since 10m
```

**Docker errors?**
- Make sure Docker Desktop is running
- Run `docker ps` to verify

## Cleanup

```bash
./scripts/destroy.sh
```

## License

Public domain (Unlicense) - free for any use.
