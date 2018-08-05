#!/bin/bash

postgres=$1

# Configure setup.cfg with Postgres private DNS
sed -i 's/dns-postgres.*/dns = ${postgres}'

# Install gunicorn
sudo pip install gunicorn

# Deploy app
nohup gunicorn app:app -b 0.0.0.0:8000