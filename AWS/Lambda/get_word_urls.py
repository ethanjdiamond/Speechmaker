import boto3
import random
import urllib

client = boto3.client("s3")


def get_word_urls(event, context):
    bucket = event["bucket"]
    app = event["app"]
    type = event["type"]
    key = urllib.unquote(event["key"]).decode("utf8")

    key_collection = client.list_objects_v2(
        Bucket=bucket, Prefix=app + "/" + type + "/" + key + "/"
    )
    keys = map(lambda key: key["Key"], key_collection["Contents"])
    if not keys[0].endswith(".mp4"):
        keys.pop(0)  # Remove the word folder
    key = keys[random.randint(0, len(keys) - 1)]
    url = client.generate_presigned_url(
        "get_object", Params={"Bucket": bucket, "Key": key}, ExpiresIn=600
    )
    response = {"url": url}

    return response
