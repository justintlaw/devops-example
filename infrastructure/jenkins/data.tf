# This is how you import state from another Terraform project
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket                  = "terraform-state-ljustint-tutorial" # TODO: YOUR BUCKET NAME HERE
    key                     = "devops-example-networking"
    region                  = "us-west-2"
  }
}

# The latest 20.04 Ubuntu AMI
data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# We can assign the outputs of the state we import to a local variable
# to allow easier access.
locals {
  networking = data.terraform_remote_state.networking.outputs
}
