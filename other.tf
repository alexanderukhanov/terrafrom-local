terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS Account ID"
  default     = "YOUR_AWS_ACCOUNT_NUMBER"
}

locals {
  json_data  = file("./data.json")
  tf_data    = jsondecode(local.json_data)
}
