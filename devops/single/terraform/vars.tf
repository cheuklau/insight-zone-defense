/*

var.tf 

This file initializes Terraform variables.

Please specify the following environment variables:
TF_VAR_AWS_ACCESS_KEY = <your-access-key>
TF_VAR_AWS_SECRET_KEY = <your-secret-key>

*/

# Variables used in provider.tf
variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {
	default = "us-west-2"
}

# Variables used in instance.tf
variable "AMIS" {
  type = "map"
  default = {
    spark    = "ami-07aac5ac970466648"
    postgres = "ami-0bc4e1746a5de0c2a"
    flask    = "todo"
  }
}
variable "NUM_WORKERS" {
  default = 2
}

# Variables used in key.tf
variable "PATH_TO_PUBLIC_KEY" {
  default = "mykeypair.pub"
}

# Variables
variable "PATH_TO_PRIVATE_KEY" {
  default = "/Users/cheuklau/Documents/GitHub/insight_devops_project/devops/Initial/test/mykeypair"
}