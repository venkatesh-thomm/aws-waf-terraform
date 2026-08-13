import os
import json
import boto3


sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def lambda_handler(event, context):

    print("Received SQS event")

    for record in event["Records"]:

        message = json.loads(record["body"])

        action = message.get("action")
        client_ip = message.get("client_ip")
        country = message.get("country")
        uri = message.get("uri")
        method = message.get("method")

        alert_message = f"""
WAF SECURITY ALERT

Action      : {action}
Client IP   : {client_ip}
Country     : {country}
HTTP Method : {method}
URI         : {uri}
"""

        print(alert_message)

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="WAF Security Alert - Request Blocked",
            Message=alert_message
        )

    return {
        "statusCode": 200,
        "body": "SQS messages processed successfully"
    }