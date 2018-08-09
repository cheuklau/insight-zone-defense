#!/bin/bash

# Note: First source the virtual Python env
#       source env/bin/activate

# Read in ELB URL
ELB=$1

# Install locustio
pip install locustio

# Fix gevent compatibility issue
pip install -U --force-reinstall --no-binary :all: gevent

# Start locust given ELB URL
locust --host=http://${ELB}

# Open a Locust browser
open http://127.0.0.1:8089/

