#!/bin/bash

postgres=$1
sparkmaster=$2

# Install dependencies
sudo pip install configparser
sudo pip --no-cache-dir install pyspark

# Install Git and clone repo
sudo apt-get install git-core
git clone https://github.com/cheuklau/insight_devops_airaware.git

# Configure setup.cfg with Postgres and Spark master private DNS
sed -i 's/dns-postgres.*/dns = ${postgres}'
sed -i 's/dns-spark.*/dns = ${sparkmaster}:7077'
