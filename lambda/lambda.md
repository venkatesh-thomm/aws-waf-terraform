# AWS WAF Security Alerting - Lambda Architecture

## Lambda Overview

This project uses AWS Lambda to process WAF security events.

We implemented the Lambda architecture in two stages.

---

# 1. Initial Architecture - Lambda Directly to SNS

Initially, we created one Lambda function to process WAF blocked-request logs.

### Architecture

WAF
 |
 | Blocked Request
 v
CloudWatch Logs
 |
 | BLOCK event
 v
Lambda #1
 |
 | SNS Publish
 v
SNS Topic
 |
 v
Email


### Flow

1. A client sends a request to the Application Load Balancer.
2. AWS WAF evaluates the request.
3. If the request matches the blocked IP rule, WAF returns HTTP 403.
4. WAF sends the request details to the CloudWatch log group.
5. A CloudWatch Logs subscription filter looks for:

   `action = BLOCK`

6. The subscription filter invokes Lambda #1.
7. Lambda #1 reads and decodes the CloudWatch Logs event.
8. Lambda #1 extracts useful information such as:

   - Action
   - Client IP
   - Country
   - HTTP method
   - URI

9. Lambda #1 publishes the alert directly to SNS.
10. SNS sends the notification to the subscribed email address.

### Initial Lambda

Lambda function:

`waf-lab-alert`

The initial Lambda had two main responsibilities:

- Process the WAF log event.
- Send the notification through SNS.

### Initial Architecture

WAF
 |
 v
CloudWatch Logs
 |
 v
waf-lab-alert Lambda
 |
 v
SNS
 |
 v
Email

This architecture was successfully tested and an email notification was received.

---

# 2. Improved Architecture - SQS + Second Lambda

After the direct Lambda-to-SNS implementation was working, we introduced SQS and a second Lambda.

The purpose was to make the architecture more decoupled and resilient.

### New Architecture

WAF
 |
 v
CloudWatch Logs
 |
 v
Lambda #1
 |
 v
SQS
 |
 v
Lambda #2
 |
 v
SNS
 |
 v
Email


## Lambda #1 - Alert Lambda

Lambda function:

`waf-lab-alert`

### Responsibility

Lambda #1 receives the WAF log event from CloudWatch Logs.

It:

1. Decodes the CloudWatch Logs event.
2. Extracts the WAF request information.
3. Creates a simplified JSON message.
4. Sends the message to SQS.

Example message:

```json
{
  "action": "BLOCK",
  "client_ip": "103.187.217.239",
  "country": "IN",
  "uri": "/",
  "method": "GET"
}

``` text
Important

Lambda #1 no longer sends the email directly.

Instead:

Lambda #1
|
v
SQS

Lambda #2 Flow

SQS
|
| Message
v
waf-lab-alert-processor
|
| SNS Publish
v
SNS
|
v
Email

##Architecture

SQS Main Queue
|
+---- Success ----> Lambda #2 ----> SNS ----> Email
|
+---- Failure x3 -----------------> DLQ



```

                    AWS WAF
                       |
                       | BLOCK
                       v
               CloudWatch Logs
                       |
                       | BLOCK event
                       v
              Lambda #1
            waf-lab-alert
                       |
                       | Send message
                       v
                  SQS Queue
              waf-lab-alerts
                       |
                       | Trigger
                       v
              Lambda #2
       waf-lab-alert-processor
                       |
                       | Publish
                       v
                     SNS
                       |
                       v
                    Email

## Failure 

```

                  SQS Queue
                      |
                      v
              Lambda #2
                      |
                 Processing
                   fails
                      |
                      v
                  Retry
                      |
              3 failed attempts
                      |
                      v
                    DLQ
```                    