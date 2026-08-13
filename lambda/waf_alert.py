import os
import json
import gzip
import base64
import boto3


sqs = boto3.client("sqs")

SQS_QUEUE_URL = os.environ["SQS_QUEUE_URL"]


def lambda_handler(event, context):

    print("Received WAF event")

    compressed_payload = base64.b64decode(
        event["awslogs"]["data"]
    )

    uncompressed_payload = gzip.decompress(
        compressed_payload
    )

    payload = json.loads(uncompressed_payload)

    print(json.dumps(payload))

    for log_event in payload.get("logEvents", []):

        message = json.loads(log_event["message"])

        action = message.get("action")

        client_ip = message.get(
            "httpRequest", {}
        ).get("clientIp")

        country = message.get(
            "httpRequest", {}
        ).get("country")

        uri = message.get(
            "httpRequest", {}
        ).get("uri")

        method = message.get(
            "httpRequest", {}
        ).get("httpMethod")

        alert = {
            "action": action,
            "client_ip": client_ip,
            "country": country,
            "uri": uri,
            "method": method
        }

        print(
            "Sending alert to SQS:",
            json.dumps(alert)
        )

        sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps(alert)
        )

    return {
        "statusCode": 200,
        "body": "WAF event sent to SQS"
    }