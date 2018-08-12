/*

var.tf 

This file initializes Terraform variables.

Please specify the following environment variables:
TF_VAR_AWS_ACCESS_KEY = <your-access-key>
TF_VAR_AWS_SECRET_KEY = <your-secret-key>

*/

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

# Overwritten by build.sh
variable "AWS_REGION" { default = "us-west-2" }

# Overwritten by build.sh
variable "AMIS" {
  type = "map"
  default = {
    spark = "ami-09550b84dfba8f5cf"
    postgres = "ami-0ac32ff18b7e18d36"
    flask = "ami-0a48b682d7342a489"
    ubuntu = "ami-ba602bc2"
  }
}

# Overwritten by build.sh
variable "NUM_WORKERS" { default = 6 }

# Overwritten by build.sh
variable "PATH_TO_PUBLIC_KEY" { default = "/Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/multi_with_asg/terraform/mykeypair.pub" }

# Overwritten by build.sh
variable "PATH_TO_PRIVATE_KEY" { default = "/Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/multi_with_asg/terraform/mykeypair" }
