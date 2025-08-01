import json
import boto3
import base64
import os
import uuid

s3_client = boto3.client('s3')
BUCKET = os.environ['BUCKET']

def lambda_handler(event, context):
    # event["body"] is base64-encoded image
    body = event["body"]
    if event.get("isBase64Encoded"):
        file_content = base64.b64decode(body)
    else:
        file_content = body.encode('utf-8')

    # Unique filename
    name = str(uuid.uuid4()) + ".jpg"
    key = f"uploads/{name}"

    s3_client.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=file_content,
        ContentType="image/jpeg"
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Uploaded!", "image_key": key}),
    }