variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "availability_zone_1" {
  type    = string
  default = "us-east-1a"
}

variable "availability_zone_2" {
  type    = string
  default = "us-east-1b"
}


variable "instance_type" {
  type    = string
  default = "t3.micro"
}



variable "domain_name" {
  description = "Domain name for ACM certificate"
  type        = string
  default     = "venkatesh.fun"

}

variable "zone_id" {
  description = "Route53 Hosted Zone ID for domain validation"
  type        = string
  default     = "Z00574303OXB3420S598P"

}

variable "alert_email" {
  description = "Email address for WAF alerts"
  type        = string
}
