import boto3
import json
import datetime

client = boto3.client("s3")
response_cache = {}  # We're going to store these in memory to cache them


def get_subfolders(bucket, app, folder):
    subfolders = []
    paginator = client.get_paginator("list_objects")
    page_iterator = paginator.paginate(
        Bucket=bucket, Prefix=app + "/" + folder + "/", Delimiter="/"
    )
    for page in page_iterator:
        for r in page.get("CommonPrefixes"):
            subfolders.append(r.get("Prefix").split("/")[-2])
    return subfolders


def get_words(event, context):
    global response_cache

    bucket = event["bucket"]
    app = event["app"]

    if not bucket in response_cache:
        response_cache[bucket] = {}

    if not app in response_cache[bucket]:
        response_cache[bucket][app] = {}

    if not "response" in response_cache[bucket][
        app
    ] or datetime.datetime.now() > response_cache[bucket][app][
        "last_update"
    ] + datetime.timedelta(
        seconds=24 * 60 * 60
    ):
        words = get_subfolders(bucket, app, "words")
        pauses = get_subfolders(bucket, app, "pauses")
        response = {"words": words, "pauses": pauses}

        # Don't cache if we're in dev
        if "dev" in bucket:
            return response

        response_cache[bucket][app]["response"] = response
        response_cache[bucket][app]["last_update"] = datetime.datetime.now()

    return response_cache[bucket][app]["response"]
