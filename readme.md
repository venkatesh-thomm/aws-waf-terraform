
## Overview

This project provisions a secure and monitored AWS web application infrastructure using **Terraform**.


## Architecture

```text
                         Internet
                            |
                            v
                    Route 53 / Domain
                            |
                            v
                         AWS WAF
                     /             \
                    /               \
                 BLOCK             ALLOW
                   |                 |
                  403                v
                              Application LB
                                  :443
                                    |
                              Target Group
                              /           \
                             /             \
                            v               v
                       RHEL EC2-1      RHEL EC2-2
                         Apache          Apache
                            \             /
                             \           /
                              \         /
                           CloudWatch
                              |
                    +---------+---------+
                    |                   |
                WAF Logs            Dashboard
                    |
                 CloudTrail

WAF Blocked Requests
        |
        v
CloudWatch Alarm
        |
        v
       SNS
        |
        v
      Email
```


## Terraform Structure

Example project structure:

```text
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
├── outputs.tf
└── terraform.tfvars
```

---

## Terraform Commands

Initialize:

```bash
terraform init
```

Format:

```bash
terraform fmt -recursive
```

Validate:

```bash
terraform validate
```

Review changes:

```bash
terraform plan
```

Create/update infrastructure:

```bash
terraform apply
```

Destroy infrastructure:

```bash
terraform destroy
```

---


## Security Flow

```text
Internet
   |
   v
AWS WAF
   |
   +---- Block malicious/blocked traffic
   |
   +---- Allow legitimate traffic
                |
                v
             ALB :443
                |
                v
           Target Group
             /      \
            v        v
          EC2-1    EC2-2
            |        |
          Apache   Apache
```

## Monitoring Flow

```text
WAF
 |
 +---- CloudWatch Logs
 |
 +---- CloudWatch Metrics
 |
 +---- CloudWatch Dashboard
 |
 +---- CloudWatch Alarm
            |
            v
           SNS
            |
            v
          Email
```