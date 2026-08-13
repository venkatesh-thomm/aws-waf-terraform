# AWS WAF Security & Monitoring Lab

## Overview

This project provisions a secure and monitored AWS web application infrastructure using **Terraform**.

The environment demonstrates how to protect an internet-facing Application Load Balancer using **AWS WAF**, monitor infrastructure using **Amazon CloudWatch**, collect security and network logs, and automatically notify administrators when WAF requests are blocked.

The project also demonstrates:

- Infrastructure as Code using Terraform
- AWS WAF protection
- ALB and EC2 deployment
- HTTPS
- CloudWatch monitoring
- CloudWatch alarms
- SNS notifications
- Python Lambda automation
- SQS and Dead Letter Queue
- IAM least privilege
- AWS Systems Manager (SSM)
- VPC Flow Logs
- CloudTrail auditing

---

# Architecture

```text
                            Internet
                                |
                                v
                         +-------------+
                         |   AWS WAF   |
                         |   Web ACL   |
                         +------+------+
                                |
                    +-----------+-----------+
                    |                       |
                  ALLOW                   BLOCK
                    |                       |
                    v                       v
                  ALB                 WAF CloudWatch
                    |                     Logs
                    |                       |
                    |                       v
                    |                 Alert Lambda
                    |                       |
                    |                       v
                    |                      SQS
                    |                       |
                    |                       v
                    |               Processor Lambda
                    |                       |
                    |                       v
                    |                      SNS
                    |                       |
                    |                       v
                    |                     Email
                    |
             +------+------+
             |             |
             v             v
           EC2-1         EC2-2
          Apache        Apache
             |             |
             +------+------+
                    |
                    v
                 Response
```

#### Failure Case 
```
              SQS Failure Handling

                    SQS
                     |
                     v
             Processor Lambda
                     |
                +----+----+
                |         |
             Success    Failure
                |         |
                v         v
               SNS       DLQ

```

### Terraform Structure

``` text 
terraform-waf/
│
├── provider.tf
├── variables.tf
├── locals.tf
├── vpc.tf
├── security-groups.tf
├── ec2.tf
├── alb.tf
├── waf.tf
├── acm.tf
├── route53.tf
├── cloudwatch.tf
├── sns.tf
├── alarms.tf
├── iam.tf
├── sqs.tf
├── lambda.tf
├── logging.tf
├── outputs.tf
├── terraform.tfvars
│
└── lambda/
    ├── waf_alert.py
    └── waf_processor.py
```                    


### Security Flow

Internet
   |
   v
AWS WAF
   |
   +---- BLOCK
   |       |
   |       v
   |   CloudWatch Logs
   |       |
   |       v
   |   Alert Lambda
   |       |
   |       v
   |      SQS
   |       |
   |       v
   | Processor Lambda
   |       |
   |       v
   |      SNS
   |       |
   |       v
   |     Email
   |
   +---- ALLOW
           |
           v
        ALB :443
           |
           v
      Target Group
        /       \
       v         v
    EC2-1      EC2-2
    Apache     Apache