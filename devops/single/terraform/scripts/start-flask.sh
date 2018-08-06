#!/bin/bash

postgres=$1
sparkmaster=$2

APPHOME='/home/ubuntu/insight_devops_airaware/AirAware'

# Configure setup.cfg with Postgres and Spark master private DNS
sed -i "/dns-postgres/c\dns = ${postgres}" ${APPHOME}/setup.cfg
sed -i "/dns-spark/c\dns = ${sparkmaster}:7077" ${APPHOME}/setup.cfg

# Install gunicorn
sudo pip install gunicorn

# Deploy app
cd ${APPHOME}/flask
gunicorn app:app --bind=0.0.0.0:8000 --daemon
