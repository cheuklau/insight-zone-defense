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
    spark = "ami-02108ce2dedbd8a09"
    postgres = "ami-069e44284c50b1da1"
    flask = "ami-0c8d96050e64089ab"
    ubuntu = "ami-ba602bc2"
  }
}

# Overwritten by build.sh
variable "NUM_WORKERS" { default = 5 }

# Overwritten by build.sh
variable "PATH_TO_PUBLIC_KEY" { default = "/Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/single_with_asg/terraform/mykeypair.pub" }

# Overwritten by build.sh
variable "PATH_TO_PRIVATE_KEY" { default = "/Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/single_with_asg/terraform/mykeypair" }
