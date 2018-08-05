#!/bin/bash

####################################################################
# User parameters
####################################################################

# Number of Spark worker nodes
NSPARK=3

# Path to public and private keys
PUBLICKEY='/Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/single/terraform/mykeypair.pub'
PRIVATEKEY='/Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/single/terraform/mykeypair'

####################################################################

# Create AMIs for Spark, Postgresql and Flask
packer build -machine-readable packer/packer-spark.json | tee packer-spark.log
packer build -machine-readable packer/packer-postgresql.json | tee packer-postgresql.log
packer build -machine-readable packer/packer-flask.json | tee packer-flask.log

# Gather AMI IDs
SPARK_AMI_ID=`egrep -oe 'ami-.{8}' packer-spark.log | tail -n1`
POSTGRESQL_AMI_ID=`egrep -oe 'ami-.{8}' packer-spark.log | tail -n1`
FLASK_AMI_ID=`egrep -oe 'ami-.{8}' packer-spark.log | tail -n1`

# Assign AMI IDs to Terraform
gsed -i 's/spark.*/    spark = ${SPARK_AMI_ID}/' /Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/single/terraform/vars.tf
gsed -i 's/postgres.*/    postgres = ${POSTGRESQL_AMI_ID}/' /Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/single/terraform/vars.tf
gsed -i 's/flask.*/    flask = ${FLASK_AMI_ID}/' /Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/single/terraform/vars.tf

# Set number of Spark worker nodes
gsed -i 's/NUM_WORKERS.*/variable "NUM_WORKERS" { default = ${NSPARK} }/' /Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/single/terraform/vars.tf

# Set public and private keys
gsed -i 's/PATH_TO_PUBLIC_KEY.*/variable "PATH_TO_PUBLIC_KEY" { default = "${PUBLICKEY}" }'
gsed -i 's/PATH_TO_PRIVATE_KEY.*/variable "PATH_TO_PRIVATE_KEY" { default = "${PRIVATEKEY}" }'

# Run Terraform
cd terraform
terraform init 
terraform apply

