import os
import json
import gzip
import base64
import boto3


sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def lambda_handler(event, context):

    print("Received event")

    # CloudWatch Logs subscription data
    compressed_payload = base64.b64decode(event["awslogs"]["data"])

    uncompressed_payload = gzip.decompress(compressed_payload)

    payload = json.loads(uncompressed_payload)

    print(json.dumps(payload))

    for log_event in payload.get("logEvents", []):

        message = json.loads(log_event["message"])

        action = message.get("action")
        client_ip = message.get("httpRequest", {}).get("clientIp")
        country = message.get("httpRequest", {}).get("country")
        uri = message.get("httpRequest", {}).get("uri")
        method = message.get("httpRequest", {}).get("httpMethod")
        host = message.get("httpRequest", {}).get("headers", [])

        alert_message = f"""
WAF SECURITY ALERT

Action      : {action}
Client IP   : {client_ip}
Country     : {country}
HTTP Method : {method}
URI         : {uri}

Host Information:
{json.dumps(host, indent=2)}
"""

        print(alert_message)

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="WAF Security Alert - Request Blocked",
            Message=alert_message
        )

    return {
        "statusCode": 200,
        "body": "WAF event processed successfully"
    }