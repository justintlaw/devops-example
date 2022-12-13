terraform {
  # Determines what to use to store terraform state
  backend "s3" {
    bucket                  = "terraform-state-ljustint-tutorial" # TODO: YOUR BUCKET NAME HERE
    key                     = "devops-example-jenkins"
    region                  = "us-west-2"
  }
  # Where Terraform will get the provider from
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Initialize the provider
provider "aws" {
  region = "us-west-2"
}
