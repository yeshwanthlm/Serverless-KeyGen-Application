import json
import os
import uuid
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs = boto3.client("sqs")
QUEUE_URL = os.environ["SQS_QUEUE_URL"]

def lambda_handler(event, context):
    """
    Handle POST /keygen requests.
    Generates a unique request ID and enqueues the request to SQS.
    """
    try:
        body = json.loads(event.get("body", "{}"))
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Invalid JSON"})
        }
    
    request_id = str(uuid.uuid4())
    key_type = body.get("key_type", "rsa")
    key_bits = body.get("key_bits", 2048)
    curve = body.get("curve", "P-256")
    
    # Validate inputs
    if key_type not in ["rsa", "ed25519", "ecdsa"]:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Invalid key_type. Must be rsa, ed25519, or ecdsa"})
        }
    
    if key_type == "rsa" and key_bits not in [2048, 4096]:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Invalid key_bits. Must be 2048 or 4096 for RSA"})
        }
    
    if key_type == "ecdsa" and curve not in ["P-256", "P-384"]:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Invalid curve. Must be P-256 or P-384 for ECDSA"})
        }
    
    message = {
        "request_id": request_id,
        "key_type": key_type,
        "key_bits": key_bits,
        "curve": curve
    }
    
    try:
        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(message)
        )
        logger.info(f"Enqueued request {request_id}")
    except Exception as e:
        logger.error(f"Failed to enqueue message: {e}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Failed to process request"})
        }
    
    return {
        "statusCode": 202,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "request_id": request_id,
            "status": "queued"
        })
    }
