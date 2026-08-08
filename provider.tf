terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "venkatesh-remote"
    key            = "eks-vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "Lock-Files"
    encrypt        = true
  }
}


provider "aws" {
  region = "us-east-1"
}
