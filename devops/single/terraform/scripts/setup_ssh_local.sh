#!/bin/bash

##############################################
#
# Taken from https://github.com/InsightDataScience/pegasus/blob/master/config/ssh/setup_ssh.sh
# Run on Master node.
#
##############################################

MASTER_DNS=$1

if ! [ -f ~/.ssh/id_rsa ]; then
  ssh-keygen -f ~/.ssh/id_rsa -t rsa -P ""
fi

cat ~/.ssh/id_rsa.pub | ssh -A -o "StrictHostKeyChecking no" -i ubuntu@${MASTER_DNS} 'cat >> ~/.ssh/authorized_keys' 
