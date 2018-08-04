#!/bin/bash

MASTER_NAME=$1; shift
SLAVE_NAME=( "$@" )

echo ${MASTER_NAME%%.*} 

# ${dns%%.*}
for name in ${SLAVE_NAME[@]} 
do
    echo ${name%%.*}
done