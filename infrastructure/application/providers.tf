terraform {
  backend "s3" {
    bucket = "terraform-state-ljustint-tutorial"
    key    = "devops-example-application"
    region = "us-west-2"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
