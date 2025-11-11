import json
import os
import boto3
import logging
from decimal import Decimal

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])

def decimal_to_native(obj):
    """Convert DynamoDB Decimal types to native Python types"""
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    elif isinstance(obj, dict):
        return {k: decimal_to_native(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [decimal_to_native(i) for i in obj]
    return obj

def lambda_handler(event, context):
    """
    Handle GET /result/{id} requests.
    Retrieves key generation results from DynamoDB.
    """
    path_params = event.get("pathParameters", {})
    request_id = path_params.get("id")
    
    if not request_id:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Missing request_id"})
        }
    
    logger.info(f"Fetching result for request_id: {request_id}")
    
    try:
        response = table.get_item(Key={"request_id": request_id})
    except Exception as e:
        logger.error(f"DynamoDB error: {e}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Internal server error"})
        }
    
    item = response.get("Item")
    
    if item:
        logger.info(f"Result found for {request_id}")
        item = decimal_to_native(item)
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(item)
        }
    
    logger.info(f"Result not yet available for {request_id}")
    return {
        "statusCode": 202,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "request_id": request_id,
            "status": "pending"
        })
    }
