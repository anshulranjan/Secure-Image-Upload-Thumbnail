import os
import boto3
import json

s3 = boto3.client("s3")
BUCKET = os.environ["BUCKET"]

def lambda_handler(event, context):
    # Assume ?key=uploads/filename.jpg or thumbnails/thumb-filename.jpg
    key = event['queryStringParameters']['key']
    url = s3.generate_presigned_url(
        'get_object',
        Params={'Bucket': BUCKET, 'Key': key},
        ExpiresIn=300  # 5 min
    )
    return {
        "statusCode": 200,
        "body": json.dumps({"url": url})
    }