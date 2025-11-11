import json
import base64
import os
import time
import hashlib
import logging
from datetime import datetime
import boto3
from cryptography.hazmat.primitives.asymmetric import rsa, ed25519, ec
from cryptography.hazmat.primitives import serialization, hashes

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])

def generate_keypair(key_type, key_bits=2048, curve="P-256", expires_at=None):
    """
    Generate SSH keypair based on specified type.
    Returns (public_key_str, private_key_str, fingerprint)
    """
    if key_type == "rsa":
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=key_bits
        )
        private_format = serialization.PrivateFormat.TraditionalOpenSSL
        
    elif key_type == "ed25519":
        private_key = ed25519.Ed25519PrivateKey.generate()
        private_format = serialization.PrivateFormat.PKCS8
        
    elif key_type == "ecdsa":
        if curve == "P-256":
            curve_obj = ec.SECP256R1()
        elif curve == "P-384":
            curve_obj = ec.SECP384R1()
        else:
            raise ValueError(f"Unsupported curve: {curve}")
        
        private_key = ec.generate_private_key(curve_obj)
        private_format = serialization.PrivateFormat.PKCS8
    else:
        raise ValueError(f"Unsupported key type: {key_type}")
    
    # Generate public key in OpenSSH format
    public_key_bytes = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.OpenSSH,
        format=serialization.PublicFormat.OpenSSH
    )
    public_key_str = public_key_bytes.decode().strip()
    
    # Add expiration comment to public key
    if expires_at:
        public_key_str = f"{public_key_str} expires={expires_at}"
    
    # Generate private key in PEM format
    private_key_bytes = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=private_format,
        encryption_algorithm=serialization.NoEncryption()
    )
    private_key_str = private_key_bytes.decode()
    
    # Add expiration comment to private key
    if expires_at:
        private_key_lines = private_key_str.strip().split('\n')
        # Insert comment after the BEGIN line
        private_key_lines.insert(1, f"# Key expires at: {expires_at} UTC")
        private_key_str = '\n'.join(private_key_lines)
    
    # Calculate fingerprint (SHA256 of public key)
    fingerprint = hashlib.sha256(public_key_bytes).hexdigest()
    fingerprint_formatted = f"SHA256:{fingerprint}"
    
    return public_key_str, private_key_str, fingerprint_formatted

def lambda_handler(event, context):
    """
    Process SQS messages containing key generation requests.
    """
    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            request_id = body.get("request_id", "unknown")
            key_type = body.get("key_type", "rsa")
            key_bits = int(body.get("key_bits", 2048))
            curve = body.get("curve", "P-256")
            expires_at = body.get("expires_at")  # ISO 8601 UTC datetime
            
            logger.info(f"Processing request {request_id}: {key_type}")
            if expires_at:
                logger.info(f"Key will expire at: {expires_at}")
            
            # Generate keypair
            start_time = time.time()
            public_key, private_key, fingerprint = generate_keypair(
                key_type, key_bits, curve, expires_at
            )
            duration = time.time() - start_time
            
            logger.info(f"Generated {key_type} keypair in {duration:.2f}s")
            
            # Prepare result
            result = {
                "request_id": request_id,
                "status": "complete",
                "key_type": key_type,
                "public_key_b64": base64.b64encode(public_key.encode()).decode(),
                "private_key_b64": base64.b64encode(private_key.encode()).decode(),
                "fingerprint": fingerprint,
                "generated_at": datetime.utcnow().isoformat() + "Z",
                "ttl": int(time.time()) + 86400  # 24 hours (DynamoDB deletion)
            }
            
            # Add expiration info if provided
            if expires_at:
                result["expires_at"] = expires_at
            
            # Add type-specific metadata
            if key_type == "rsa":
                result["key_bits"] = key_bits
            elif key_type == "ecdsa":
                result["curve"] = curve
            
            # Store in DynamoDB
            table.put_item(Item=result)
            logger.info(f"Stored result for {request_id}")
            
        except Exception as e:
            logger.error(f"Failed to process message: {e}", exc_info=True)
            # Continue processing other messages
    
    return {"statusCode": 200, "body": "Processed"}
