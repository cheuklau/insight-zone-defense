/*

vars.tf

Purpose: set user-defined variables

Notes: variables are set by build.sh

*/

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "AWS_REGION" { default = "us-west-2" }

variable "AMIS" {
  type = "map"
  default = {
    spark = "ami-09550b84dfba8f5cf"
    postgres = "ami-0ac32ff18b7e18d36"
    flask = "ami-073264bd0fc497f34"
    ubuntu = "ami-ba602bc2"
  }
}

# Number of Spark workers
variable "NUM_WORKERS" { default = 6 }

variable "PATH_TO_PUBLIC_KEY" { default = "~/.ssh/mykeypair.pub" }

variable "PATH_TO_PRIVATE_KEY" { default = "~/.ssh/mykeypair" }
