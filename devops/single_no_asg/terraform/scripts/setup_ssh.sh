#!/bin/bash

##############################################
#
# Taken from https://github.com/InsightDataScience/pegasus/blob/master/config/ssh/setup_ssh.sh
# Run on Master node.
#
##############################################

KEY_NAME=$1; shift
SLAVE_DNS=( "$@" ) # This is the list of Slave DNS in the form ec2-xx-xxx-xx-xx.us-west-2.compute.amazonaws.com

sudo mv /tmp/${KEY_NAME} ~/.ssh/
sudo chmod 600 ~/.ssh/${KEY_NAME}

if ! [ -f ~/.ssh/id_rsa ]; then
    ssh-keygen -f ~/.ssh/id_rsa -t rsa -P ""
fi
sudo cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# copy id_rsa.pub in master to all slaves authorized_keys for passwordless ssh
# add additional for multiple slaves
for dns in ${SLAVE_DNS[@]}
do
  echo "Adding $dns to authorized keys..."
  cat ~/.ssh/id_rsa.pub | ssh -o "StrictHostKeyChecking no" -i ~/.ssh/${KEY_NAME} ${USER}@$dns 'cat >> ~/.ssh/authorized_keys' &
done

wait