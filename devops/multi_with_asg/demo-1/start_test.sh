#!/bin/bash

# Notes: 
# 1) First source the virtual Python env `source env/bin/activate`
# 2) Perform the following if not yet performed in virtual env:
#    - `pip install locustio`
#    - `pip install -U --force-reinstall --no-binary :all: gevent`
# 3) Run this bash script as:
# 	 bash start_test.sh <ELB-URL>
# 4) Go to browser http://127.0.0.1:8089/
# 5) In browser, enter number of target users and user ramp rate then click start

# Read in ELB URL
ELB=$1

# Start locust using ELB URL
locust --host=http://${ELB}

# Open a Locust browser
open http://127.0.0.1:8089/
