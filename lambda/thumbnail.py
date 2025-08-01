import boto3
import os
from PIL import Image
import tempfile

s3 = boto3.client("s3")
BUCKET = os.environ["BUCKET"]

def lambda_handler(event, context):
    for record in event["Records"]:
        key = record["s3"]["object"]["key"]
        if not key.startswith("uploads/"):
            continue

        # Download image to /tmp/
        tmp_file = os.path.join(tempfile.gettempdir(), os.path.basename(key))
        s3.download_file(BUCKET, key, tmp_file)

        # Make thumbnail
        outfile = os.path.join(tempfile.gettempdir(), "thumb-" + os.path.basename(key))
        with Image.open(tmp_file) as image:
            image.thumbnail((128, 128))
            image.save(outfile)

        # Upload thumbnail
        s3.upload_file(outfile, BUCKET, "thumbnails/thumb-" + os.path.basename(key))
    return { "statusCode": 200 }