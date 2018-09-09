#!/bin/bash

####################################################################
#
# Default user parameters
#
# Note: gsed used for MacOS, change if necessary
# 		Export TF_VAR_AWS_ACCESS_KEY and TF_VAR_AWS_SECRET_KEY
#
####################################################################

# Number of Spark worker nodes
NSPARK=6

# Path to public and private keys
PUBLICKEY='~/.ssh/mykeypair.pub'
PRIVATEKEY='~/.ssh/mykeypair'

# Region
REGION='us-west-2'

# Packer image version
PACKERV='1.0'

# Directories
PACKERHOME='/Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/final/packer'
TERRAFORMHOME='/Users/cheuklau/Documents/GitHub/insight_devops_airaware/devops/final/terraform'

########################################################################
#
# Parse user arguments
#
########################################################################

function usage() {
	echo "USAGE: $0 [--packer y/n] [--terraform y/n] [--help]"
	echo "Examples:"
	echo "$0 --packer y --terraform n"
	echo "$0 --packer n --terraform y"
	echo "Please change user-defined variables as necessary in build.sh:"
	echo "-Number of Spark workers"
	echo "-Path to public and private keys"
	echo "-AWS region"
	echo "-Path to Packer and Terraform directories"
	exit 1
}

if [ $# -lt 4 ]; then
	usage
fi

USEPACKER=0
USETERRAFORM=0
while [ $# -gt 0 ]
do
	case $1 in
		--packer )
			if [ $2 == "y" ]; then
				USEPACKER=1
			fi
			shift
			shift
			;;
		--terraform )
			if [ $2 == "y" ]; then
				USETERRAFORM=1
			fi
			shift
			shift
			;;
		--help )
			usage
			;;
		* )
			usage
			;;
	esac
done

########################################################################
#
# Build Packer AMIs
#
########################################################################

if [ $USEPACKER -eq 1 ]; then

	echo 'Building packer AMI...'

	# Update Packer AMI version
	gsed -i "/image_version/c\ \ \ \ \"image_version\" : \"${PACKERV}\"" ${PACKERHOME}/packer-spark.json
	gsed -i "/image_version/c\ \ \ \ \"image_version\" : \"${PACKERV}\"" ${PACKERHOME}/packer-postgresql.json
	gsed -i "/image_version/c\ \ \ \ \"image_version\" : \"${PACKERV}\"" ${PACKERHOME}/packer-flask.json
	gsed -i "/ami_name/c\ \ \ \ \"ami_name\" : \"insight-packer-spark-${PACKERV}\"" ${PACKERHOME}/packer-spark.json
	gsed -i "/ami_name/c\ \ \ \ \"ami_name\" : \"insight-packer-postgresql-${PACKERV}\"" ${PACKERHOME}/packer-postgresql.json 
	gsed -i "/ami_name/c\ \ \ \ \"ami_name\" : \"insight-packer-flask-${PACKERV}\"" ${PACKERHOME}/packer-flask.json 
	gsed -i "/scripts/c\ \ \ \ \"scripts\": \[ \"${PACKERHOME}/scripts/download-and-install-spark.sh\" \]" ${PACKERHOME}/packer-spark.json
	gsed -i "/scripts/c\ \ \ \ \"scripts\": \[ \"${PACKERHOME}/scripts/download-and-install-postgresql.sh\" \]" ${PACKERHOME}/packer-postgresql.json
	gsed -i "/scripts/c\ \ \ \ \"scripts\": \[ \"${PACKERHOME}/scripts/download-and-install-flask.sh\" \]" ${PACKERHOME}/packer-flask.json

	# Create AMIs for Spark, Postgresql and Flask
	packer build -machine-readable ${PACKERHOME}/packer-spark.json | tee ${PACKERHOME}/packer-spark.log
	packer build -machine-readable ${PACKERHOME}/packer-postgresql.json | tee ${PACKERHOME}/packer-postgresql.log
	packer build -machine-readable ${PACKERHOME}/packer-flask.json | tee ${PACKERHOME}/packer-flask.log
	mv ${PACKERHOME}/*.log ${PACKERHOME}/logs

fi

########################################################################
#
# Run Terraform
#
########################################################################

if [ $USETERRAFORM -eq 1 ]; then

	echo 'Updating Terraform options...'

	# Gather AMI IDs
	grep 'amazon-ebs: AMI: ami-' ${PACKERHOME}/logs/packer-spark.log > spark_ami_tmp.txt
	grep 'amazon-ebs: AMI: ami-' ${PACKERHOME}/logs/packer-postgresql.log > postgresql_ami_tmp.txt
	grep 'amazon-ebs: AMI: ami-' ${PACKERHOME}/logs/packer-flask.log > flask_ami_tmp.txt
	SPARK_AMI_ID=`egrep -oe 'ami-.*' spark_ami_tmp.txt | tail -n1`
	POSTGRESQL_AMI_ID=`egrep -oe 'ami-.*' postgresql_ami_tmp.txt | tail -n1`
	FLASK_AMI_ID=`egrep -oe 'ami-.*' flask_ami_tmp.txt | tail -n1`
	rm *tmp.txt

	# Set region
	gsed -i "/AWS_REGION/c\variable \"AWS_REGION\" { default = \"${REGION}\" }" ${TERRAFORMHOME}/vars.tf

	# Set AMI IDs
	gsed -i "/spark/c\ \ \ \ spark = \"${SPARK_AMI_ID}\"" ${TERRAFORMHOME}/vars.tf
	gsed -i "/postgres/c \ \ \ \ postgres = \"${POSTGRESQL_AMI_ID}\"" ${TERRAFORMHOME}/vars.tf
	gsed -i "/flask/c \ \ \ \ flask = \"${FLASK_AMI_ID}\"" ${TERRAFORMHOME}/vars.tf

	# Set number of Spark worker nodes
	gsed -i "/NUM_WORKERS/c\variable \"NUM_WORKERS\" { default = ${NSPARK} }" ${TERRAFORMHOME}/vars.tf

	# Set public and private keys
	gsed -i "/PATH_TO_PUBLIC_KEY/c\variable \"PATH_TO_PUBLIC_KEY\" { default = \"${PUBLICKEY}\" }" ${TERRAFORMHOME}/vars.tf
	gsed -i "/PATH_TO_PRIVATE_KEY/c\variable \"PATH_TO_PRIVATE_KEY\" { default = \"${PRIVATEKEY}\" }" ${TERRAFORMHOME}/vars.tf

	echo 'Starting Terraform...'

	# Run Terraform
	cd ${TERRAFORMHOME}
	terraform init 
	terraform apply

fi
