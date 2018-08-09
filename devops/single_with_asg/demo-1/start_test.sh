#!/bin/bash

# Notes: 
# 1) First source the virtual Python env `source env/bin/activate`
# 2) Perform the following if not yet performed in virtual env:
#    - `pip install locustio`
#    - `pip install -U --force-reinstall --no-binary :all: gevent`
# 

# Read in ELB URL
ELB=$1

# Start locust given ELB URL
locust --host=http://${ELB}

# Open a Locust browser
open http://127.0.0.1:8089/

