# Variables can be declared with a specified type and default value
# Values can also be set in terraform.tfvars
# Or by setting an environment variable before running 'terraform apply'
#   ex: 'TF_VAR_{your_var_here}'
variable "vpc_cidr" {
  type    = string
  default = "10.124.0.0/16"
}

# TODO: specify your personal ip when calling script
variable "access_ip" {
  type    = string
}
